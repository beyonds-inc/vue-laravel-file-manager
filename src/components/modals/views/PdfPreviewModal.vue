<template>
    <div class="modal-content fm-modal-pdf-preview">
        <div class="modal-header">
            <h5 class="modal-title w-50 text-truncate">
                {{ lang.modal.pdfPreview.title }}
                <small class="text-muted ps-3">{{ selectedItem.basename }}</small>
            </h5>
            <div class="fm-pdf-toolbar">
                <span v-if="pageCount" class="text-muted me-2">
                    {{ lang.modal.pdfPreview.pages.replace('{count}', pageCount) }}
                </span>
                <button
                    type="button"
                    class="btn btn-sm btn-light"
                    v-bind:title="lang.modal.pdfPreview.zoomOut"
                    v-bind:aria-label="lang.modal.pdfPreview.zoomOut"
                    v-bind:disabled="!pageCount || scale <= MIN_SCALE"
                    v-on:click="zoom(1 / ZOOM_STEP)"
                >
                    <i class="bi bi-zoom-out"></i>
                </button>
                <span class="fm-pdf-zoom-value">{{ Math.round(scale * 100) }}%</span>
                <button
                    type="button"
                    class="btn btn-sm btn-light"
                    v-bind:title="lang.modal.pdfPreview.zoomIn"
                    v-bind:aria-label="lang.modal.pdfPreview.zoomIn"
                    v-bind:disabled="!pageCount || scale >= MAX_SCALE"
                    v-on:click="zoom(ZOOM_STEP)"
                >
                    <i class="bi bi-zoom-in"></i>
                </button>
                <button
                    type="button"
                    class="btn btn-sm btn-light ms-1"
                    v-bind:disabled="!pageCount"
                    v-on:click="fitWidth"
                >
                    {{ lang.modal.pdfPreview.fitWidth }}
                </button>
            </div>
            <button type="button" class="btn-close" aria-label="Close" v-on:click="hideModal"></button>
        </div>
        <!-- ブラウザの PDF ビューアーは使わない。保存・印刷のボタンが出て、閲覧者でもダウンロードできてしまうため (eportal-saas #824) -->
        <div class="modal-body p-0 fm-pdf-pages" ref="pages" v-on:contextmenu.prevent>
            <p v-if="status === 'loading'" class="fm-pdf-message">{{ lang.modal.pdfPreview.loading }}</p>
            <p v-else-if="status === 'error'" class="fm-pdf-message">{{ lang.modal.pdfPreview.error }}</p>
            <div
                v-for="page in pages"
                v-bind:key="page.number"
                class="fm-pdf-page"
                v-bind:data-page="page.number"
                v-bind:style="{ width: `${page.width}px`, height: `${page.height}px` }"
            >
                <canvas></canvas>
            </div>
        </div>
    </div>
</template>

<script>
// eslint-disable-next-line import/extensions
import { getDocument, GlobalWorkerOptions, version as pdfjsVersion } from 'pdfjs-dist/legacy/build/pdf.mjs';
import modal from '../mixins/modal';
import translate from '../../../mixins/translate';

// PDF の 1pt（1/72 インチ）を CSS の px（1/96 インチ）にする倍率。100% で実寸になる
const PDF_TO_CSS_UNITS = 96 / 72;
// 最初の表示倍率の上限（幅に合わせると大きくなりすぎる横長の画面向け。pdf.js のビューアーと同じ値）
const MAX_AUTO_SCALE = 1.25;
// 前後の何 px 分のページまで先に描くか。これより離れたページは描いた中身を捨てる
const RENDER_MARGIN = '600px 0px';
// 1 つの canvas の画素数の上限。超えると iPad の Safari などで真っ白になるため、解像度を下げて描く
// （pdf.js のビューアーと同じ値）
const MAX_CANVAS_PIXELS = 2 ** 24;

/**
 * pdf.js の worker と文字の形のデータ（CMap・標準フォント）を置いた場所。
 * ePortal の blade が fmPdfjsAssetsUrl で渡す。file-manager.js に含めると資料一覧を開くたびに読み込む量が増えるため、
 * 別に置いて PDF を開いたときだけ読み込む。
 * worker は pdf.js 本体と版がそろっていないと動かないため、版ごとのフォルダに置く
 * @returns {string}
 */
function assetsUrl() {
    const url = window.fmPdfjsAssetsUrl || '/vendor/file-manager/pdfjs/';

    return `${url.endsWith('/') ? url : `${url}/`}${pdfjsVersion}/`;
}

export default {
    name: 'PdfPreviewModal',
    mixins: [modal, translate],
    data() {
        return {
            status: 'loading',
            pageCount: 0,
            pages: [],
            scale: 1,
            MIN_SCALE: 0.25,
            MAX_SCALE: 4,
            ZOOM_STEP: 1.25,
        };
    },
    computed: {
        /**
         * Selected file
         * @returns {*}
         */
        selectedItem() {
            return this.$store.getters['fm/selectedItems'][0];
        },

        /**
         * Object URL of the PDF blob created by the openPDF action
         * @returns {*}
         */
        pdfUrl() {
            return this.$store.state.fm.modal.pdfPreviewUrl;
        },
    },
    watch: {
        pdfUrl() {
            this.load();
        },
    },
    created() {
        // pdf.js のオブジェクトは Vue の reactive にすると動かないため、data には置かない
        this.pdfDocument = null;
        this.pageSizes = [];
        this.renderTasks = new Map();
        this.renderedScale = new Map();
        this.observer = null;
        this.loadingTask = null;
        // 読み込みの番号。閉じたり別の PDF に変わったりしたら進め、前の読み込みの結果を捨てる
        this.loadId = 0;
    },
    mounted() {
        this.observer = new IntersectionObserver(this.onPagesVisible, {
            root: this.$refs.pages,
            rootMargin: RENDER_MARGIN,
        });
        this.load();
    },
    beforeUnmount() {
        this.observer.disconnect();
        this.releaseDocument();
    },
    methods: {
        /**
         * PDF を読み込み、ページの枠を並べる。中身は見えるところだけ描く
         */
        async load() {
            this.releaseDocument();
            const { loadId } = this;
            this.status = 'loading';
            this.pageCount = 0;
            this.pages = [];

            if (!this.pdfUrl) {
                return;
            }

            let loadingTask = null;
            try {
                GlobalWorkerOptions.workerSrc = `${assetsUrl()}pdf.worker.min.js`;
                const data = await (await fetch(this.pdfUrl)).arrayBuffer();
                if (loadId !== this.loadId) {
                    return;
                }

                loadingTask = getDocument({
                    data,
                    cMapUrl: `${assetsUrl()}cmaps/`,
                    cMapPacked: true,
                    standardFontDataUrl: `${assetsUrl()}standard_fonts/`,
                    isEvalSupported: false,
                    enableXfa: false,
                });
                this.loadingTask = loadingTask;
                const pdfDocument = await loadingTask.promise;
                const firstPage = await pdfDocument.getPage(1);

                // 読み込み中に閉じたり別の PDF に変わったりしたら、この読み込みの結果は捨てる
                if (loadId !== this.loadId) {
                    loadingTask.destroy();
                    return;
                }

                this.pdfDocument = pdfDocument;
                const firstSize = firstPage.getViewport({ scale: PDF_TO_CSS_UNITS });
                // 大きさが違うページは、描くときに直す
                this.pageSizes = Array.from({ length: pdfDocument.numPages }, () => ({
                    width: firstSize.width,
                    height: firstSize.height,
                }));
                this.scale = this.autoScale(firstSize);
                this.pageCount = pdfDocument.numPages;
                this.updatePageBoxes();
                this.status = 'ready';

                await this.$nextTick();
                this.$refs.pages.querySelectorAll('.fm-pdf-page').forEach((el) => this.observer.observe(el));
            } catch (error) {
                if (loadId === this.loadId) {
                    console.error(error);
                    this.status = 'error';
                } else if (loadingTask) {
                    loadingTask.destroy();
                }
            }
        },

        /**
         * 読み込んだ PDF と、描いている途中の処理を片付ける
         */
        releaseDocument() {
            this.loadId += 1;
            this.renderTasks.forEach((task) => task.cancel());
            this.renderTasks.clear();
            this.renderedScale.clear();
            if (this.observer) {
                this.observer.disconnect();
            }
            if (this.loadingTask) {
                this.loadingTask.destroy();
                this.loadingTask = null;
            }
            this.pdfDocument = null;
        },

        /**
         * 最初の表示倍率。幅に合わせるが、大きくなりすぎないようにする
         * @param size 100% のときのページの大きさ
         * @returns {number}
         */
        autoScale(size) {
            return Math.min(this.fitWidthScale(size), MAX_AUTO_SCALE);
        },

        /**
         * ページの幅を表示する場所の幅に合わせる倍率
         * @param size 100% のときのページの大きさ
         * @returns {number}
         */
        fitWidthScale(size) {
            const available = this.$refs.pages.clientWidth - 40;

            return Math.max(this.MIN_SCALE, Math.min(this.MAX_SCALE, available / size.width));
        },

        /**
         * 拡大・縮小する
         * @param factor
         */
        zoom(factor) {
            this.setScale(Math.max(this.MIN_SCALE, Math.min(this.MAX_SCALE, this.scale * factor)));
        },

        /**
         * 幅に合わせる
         */
        fitWidth() {
            this.setScale(this.fitWidthScale(this.pageSizes[0]));
        },

        /**
         * 倍率を変え、見えているページを描き直す
         * @param scale
         */
        setScale(scale) {
            const container = this.$refs.pages;
            // 見ている場所がずれないよう、倍率に合わせてスクロール位置も動かす
            const ratio = scale / this.scale;
            const scrollTop = container.scrollTop * ratio;

            this.scale = scale;
            this.updatePageBoxes();
            this.$nextTick(() => {
                container.scrollTop = scrollTop;
                this.observer.disconnect();
                container.querySelectorAll('.fm-pdf-page').forEach((el) => this.observer.observe(el));
            });
        },

        /**
         * ページの枠の大きさを、今の倍率に合わせる
         */
        updatePageBoxes() {
            this.pages = this.pageSizes.map((size, index) => ({
                number: index + 1,
                width: Math.floor(size.width * this.scale),
                height: Math.floor(size.height * this.scale),
            }));
        },

        /**
         * 見えてきたページを描く
         * @param entries
         */
        onPagesVisible(entries) {
            entries.forEach((entry) => {
                const number = Number(entry.target.dataset.page);
                if (entry.isIntersecting) {
                    this.renderPage(number, entry.target);
                } else {
                    this.clearPage(number, entry.target);
                }
            });
        },

        /**
         * 見えている場所から離れたページの中身を捨てる。描いたままにすると、ページ数に比例してメモリを使うため
         * @param number
         * @param box
         */
        clearPage(number, box) {
            if (this.renderTasks.has(number)) {
                this.renderTasks.get(number).cancel();
                this.renderTasks.delete(number);
            }
            this.renderedScale.delete(number);

            const canvas = box.querySelector('canvas');
            canvas.width = 0;
            canvas.height = 0;
        },

        /**
         * 1 ページを canvas に描く
         * @param number
         * @param box
         */
        async renderPage(number, box) {
            const { pdfDocument } = this;
            if (!pdfDocument || this.renderedScale.get(number) === this.scale) {
                return;
            }

            const { scale } = this;
            this.renderedScale.set(number, scale);
            if (this.renderTasks.has(number)) {
                this.renderTasks.get(number).cancel();
            }

            try {
                const page = await pdfDocument.getPage(number);
                if (pdfDocument !== this.pdfDocument || scale !== this.scale) {
                    return;
                }

                const viewport = page.getViewport({ scale: scale * PDF_TO_CSS_UNITS });
                const size = this.pageSizes[number - 1];
                const actual = page.getViewport({ scale: PDF_TO_CSS_UNITS });
                if (size.width !== actual.width || size.height !== actual.height) {
                    this.pageSizes[number - 1] = { width: actual.width, height: actual.height };
                    this.pages[number - 1] = {
                        number,
                        width: Math.floor(viewport.width),
                        height: Math.floor(viewport.height),
                    };
                }

                const canvas = box.querySelector('canvas');
                // 高解像度の画面ではきれいに描くため画素を増やすが、上限を超えるときは減らす
                const cssPixels = viewport.width * viewport.height;
                const outputScale = Math.min(window.devicePixelRatio || 1, Math.sqrt(MAX_CANVAS_PIXELS / cssPixels));
                canvas.width = Math.floor(viewport.width * outputScale);
                canvas.height = Math.floor(viewport.height * outputScale);
                canvas.style.width = `${Math.floor(viewport.width)}px`;
                canvas.style.height = `${Math.floor(viewport.height)}px`;

                const task = page.render({
                    canvasContext: canvas.getContext('2d'),
                    viewport,
                    transform: outputScale !== 1 ? [outputScale, 0, 0, outputScale, 0, 0] : null,
                });
                this.renderTasks.set(number, task);
                await task.promise;
                this.renderTasks.delete(number);
            } catch (error) {
                this.renderTasks.delete(number);
                if (error && error.name === 'RenderingCancelledException') {
                    return;
                }
                this.renderedScale.delete(number);
                console.error(error);
            }
        },
    },
};
</script>

<style lang="scss">
.fm-modal-pdf-preview {
    .modal-header {
        gap: 0.5rem;
    }

    .fm-pdf-toolbar {
        display: flex;
        align-items: center;
        gap: 0.25rem;
        margin-left: auto;
        white-space: nowrap;
    }

    .fm-pdf-zoom-value {
        min-width: 3.5em;
        text-align: center;
    }

    .fm-pdf-pages {
        height: 75vh;
        overflow: auto;
        background-color: #525659;
        padding: 20px 0;
    }

    .fm-pdf-page {
        position: relative;
        margin: 0 auto 12px;
        background-color: #fff;
        box-shadow: 0 1px 4px rgba(0, 0, 0, 0.4);

        canvas {
            display: block;
        }
    }

    .fm-pdf-message {
        color: #fff;
        text-align: center;
        margin: 2rem 0;
    }
}
</style>
