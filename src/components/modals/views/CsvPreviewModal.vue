<template>
    <div class="modal-content fm-modal-csv-preview">
        <div class="modal-header">
            <h5 class="modal-title w-75 text-truncate">
                {{ lang.modal.csvPreview.title }}
                <small class="text-muted ps-3">{{ target.basename }}</small>
            </h5>
            <button type="button" class="btn-close" aria-label="Close" v-on:click="hideModal"></button>
        </div>
        <div class="modal-body">
            <div v-if="truncated" class="alert alert-warning py-2" role="alert">
                {{ truncatedMessage }}
            </div>
            <div v-if="!encodingDetected" class="alert alert-warning py-2" role="alert">
                {{ encodingGuessedMessage }}
            </div>
            <p v-if="loaded && rows.length === 0" class="text-muted mb-0">{{ lang.modal.csvPreview.empty }}</p>
            <div v-if="rows.length > 0" class="fm-csv-table">
                <table class="table table-sm table-bordered mb-0">
                    <thead>
                        <tr>
                            <th v-for="(cell, index) in headerRow" v-bind:key="index">{{ cell }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="(row, rowIndex) in bodyRows" v-bind:key="rowIndex">
                            <td v-for="(cell, cellIndex) in row" v-bind:key="cellIndex">{{ cell }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</template>

<script>
import modal from '../mixins/modal';
import translate from '../../../mixins/translate';
import GET from '../../../http/get';
import EventBus from '../../../emitter';

// サーバーが返す mbstring の文字コード名を、画面に出す名前にする
const ENCODING_LABELS = { 'SJIS-win': 'Shift_JIS', 'eucJP-win': 'EUC-JP' };

export default {
    name: 'CsvPreviewModal',
    mixins: [modal, translate],
    data() {
        return {
            rows: [],
            truncated: false,
            encodingDetected: true,
            encoding: '',
            loaded: false,
            isUnmounted: false,
        };
    },
    computed: {
        /**
         * The double-clicked file ({ disk, path, basename })
         * @returns {*}
         */
        target() {
            return this.$store.state.fm.modal.csvPreviewTarget || { disk: '', path: '', basename: '' };
        },

        /**
         * Number of columns of the widest row (rows can have different lengths)
         * @returns {number}
         */
        columnCount() {
            return this.rows.reduce((max, row) => Math.max(max, row.length), 0);
        },

        /**
         * First row is shown as the header
         * @returns {string[]}
         */
        headerRow() {
            return this.fillRow(this.rows[0] || []);
        },

        /**
         * @returns {string[][]}
         */
        bodyRows() {
            return this.rows.slice(1).map((row) => this.fillRow(row));
        },

        /**
         * @returns {string}
         */
        truncatedMessage() {
            return this.lang.modal.csvPreview.truncated.replace('{count}', this.rows.length);
        },

        /**
         * @returns {string}
         */
        encodingGuessedMessage() {
            return this.lang.modal.csvPreview.encodingGuessed.replace(
                '{encoding}',
                ENCODING_LABELS[this.encoding] || this.encoding
            );
        },
    },
    mounted() {
        GET.csvPreview(this.target.disk, this.target.path)
            .then((response) => {
                if (this.isUnmounted) {
                    return;
                }

                // アクセス拒否などは 200 で { result: { status: 'error' } } が返り、interceptor が通知済み
                if (response.data.result && response.data.result.status === 'error') {
                    this.closeIfStillOpen();
                    return;
                }

                // 想定した形でない応答（施設選択画面の HTML など）は、空の表と取り違えないよう閉じる
                if (!Array.isArray(response.data.rows)) {
                    EventBus.emit('addNotification', {
                        status: 'error',
                        message: this.lang.response.pdfError,
                    });
                    this.closeIfStillOpen();
                    return;
                }

                this.rows = response.data.rows;
                this.truncated = response.data.truncated === true;
                this.encodingDetected = response.data.encoding_detected !== false;
                this.encoding = response.data.encoding || '';
                this.loaded = true;
            })
            // 表示できない理由は response interceptor が通知するので、空のモーダルは閉じる
            .catch((error) => {
                if (!error.response) {
                    console.error(error);
                }
                this.closeIfStillOpen();
            });
    },
    beforeUnmount() {
        this.isUnmounted = true;
    },
    methods: {
        /**
         * Close this modal only if it is still shown (the request can end after the user closed it and opened another modal)
         */
        closeIfStillOpen() {
            if (!this.isUnmounted) {
                this.hideModal();
            }
        },

        /**
         * Make every row as wide as the widest row
         * @param row
         * @returns {string[]}
         */
        fillRow(row) {
            const cells = row.map((cell) => (cell === null || cell === undefined ? '' : String(cell)));

            while (cells.length < this.columnCount) {
                cells.push('');
            }

            return cells;
        },
    },
};
</script>

<style lang="scss">
.fm-modal-csv-preview {
    .fm-csv-table {
        max-height: 70vh;
        overflow: auto;

        th {
            position: sticky;
            top: 0;
            background-color: var(--bs-light, #f8f9fa);
        }

        th,
        td {
            white-space: pre-wrap;
            word-break: break-word;
        }
    }
}
</style>
