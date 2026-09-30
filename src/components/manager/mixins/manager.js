// Event bus
import EventBus from '../../../emitter';
import POST from '../../../http/post';

// PDF に変換して表示する形式（eportal-saas #824）。
// PowerPoint も送り、表示できない理由（この形式のファイルは表示できません。）をサーバーから受け取って表示する
const OFFICE_PDF_EXTENSIONS = ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];

// 変換中に別のファイルを開いた場合、遅れて返った前の結果で画面を上書きしないための番号
let latestOfficeRequest = 0;

export default {
    computed: {
        /**
         * Selected disk for this manager
         * @returns {*}
         */
        selectedDisk() {
            return this.$store.state.fm[this.manager].selectedDisk;
        },

        /**
         * Selected directory for this manager
         * @returns {any}
         */
        selectedDirectory() {
            return this.$store.state.fm[this.manager].selectedDirectory;
        },

        /**
         * Files list for selected directory
         * @returns {*}
         */
        files() {
            return this.$store.getters[`fm/${this.manager}/files`];
        },

        /**
         * Directories list for selected directory
         * @returns {*}
         */
        directories() {
            return this.$store.getters[`fm/${this.manager}/directories`];
        },

        /**
         * Selected files and folders
         * @returns {*}
         */
        selected() {
            return this.$store.state.fm[this.manager].selected;
        },

        /**
         * ACL On/Off
         */
        acl() {
            return this.$store.state.fm.settings.acl;
        },

        /**
         * Check if current path is at root level
         * @return {boolean}
         */
        isRootPath() {
            return this.$store.state.fm[this.manager].selectedDirectory === null;
        },
    },
    methods: {
        /**
         * Load selected directory and show files
         * @param path
         */
        selectDirectory(path) {
            this.$store.dispatch(`fm/${this.manager}/selectDirectory`, { path, history: true });
        },

        /**
         * Level up directory
         */
        levelUp() {
            // if this a not root directory
            if (this.selectedDirectory) {
                // calculate up directory path
                const pathUp = this.selectedDirectory.split('/').slice(0, -1).join('/');

                // load directory
                this.$store.dispatch(`fm/${this.manager}/selectDirectory`, { path: pathUp || null, history: true });
            }
        },

        /**
         * Check item - selected
         * @param type
         * @param path
         */
        checkSelect(type, path) {
            return this.selected[type].includes(path);
        },

        /**
         * Select items in list (files + folders)
         * @param type
         * @param path
         * @param event
         */
        selectItem(type, path, event) {
            // search in selected array
            const alreadySelected = this.selected[type].includes(path);

            // if pressed Ctrl -> multi select
            if (event.ctrlKey || event.metaKey) {
                if (!alreadySelected) {
                    // add new selected item
                    this.$store.commit(`fm/${this.manager}/setSelected`, { type, path });
                } else {
                    // remove selected item
                    this.$store.commit(`fm/${this.manager}/removeSelected`, { type, path });
                }
            }

            // single select
            if (!event.ctrlKey && !alreadySelected && !event.metaKey) {
                this.$store.commit(`fm/${this.manager}/changeSelected`, { type, path });
            }
        },

        /**
         * Show context menu
         * @param item
         * @param event
         */
        contextMenu(item, event) {
            // el type
            const type = item.type === 'dir' ? 'directories' : 'files';
            // search in selected array
            const alreadySelected = this.selected[type].includes(item.path);

            // select this element
            if (!alreadySelected) {
                // select item
                this.$store.commit(`fm/${this.manager}/changeSelected`, {
                    type,
                    path: item.path,
                });
            }

            // create event
            EventBus.emit('contextMenu', event);
        },

        /**
         * Select and Action
         * @param path
         * @param extension
         */
        selectAction(path, extension) {
            // if is set fileCallback
            if (this.$store.state.fm.fileCallback) {
                this.$store
                    .dispatch('fm/url', {
                        disk: this.selectedDisk,
                        path,
                    })
                    .then((response) => {
                        if (response.data.result.status === 'success') {
                            this.$store.state.fm.fileCallback(response.data.url);
                        }
                    });

                return;
            }

            // if extension not defined
            if (!extension) {
                return;
            }

            // show, play..
            if (this.$store.state.fm.settings.imageExtensions.includes(extension.toLowerCase())) {
                // show image
                this.$store.commit('fm/modal/setModalState', {
                    modalName: 'PreviewModal',
                    show: true,
                });
            } else if (Object.keys(this.$store.state.fm.settings.textExtensions).includes(extension.toLowerCase())) {
                // show text file
                this.$store.commit('fm/modal/setModalState', {
                    modalName: 'TextEditModal',
                    show: true,
                });
            } else if (this.$store.state.fm.settings.audioExtensions.includes(extension.toLowerCase())) {
                // show player modal
                this.$store.commit('fm/modal/setModalState', {
                    modalName: 'AudioPlayerModal',
                    show: true,
                });
            } else if (this.$store.state.fm.settings.videoExtensions.includes(extension.toLowerCase())) {
                // show player modal
                this.$store.commit('fm/modal/setModalState', {
                    modalName: 'VideoPlayerModal',
                    show: true,
                });
            } else if (extension.toLowerCase() === 'pdf') {
                // show pdf document
                this.$store.dispatch('fm/openPDF', {
                    disk: this.selectedDisk,
                    path,
                });
            } else if (OFFICE_PDF_EXTENSIONS.includes(extension.toLowerCase())) {
                // show Word / Excel in PDF
                this.openOfficeAsPdf(this.selectedDisk, path);
            } else if (extension.toLowerCase() === 'csv') {
                // show CSV as a read-only table
                this.$store.commit('fm/modal/setCsvPreviewTarget', {
                    disk: this.selectedDisk,
                    path,
                    basename: path.split('/').pop(),
                });
                this.$store.commit('fm/modal/setModalState', {
                    modalName: 'CsvPreviewModal',
                    show: true,
                });
            }
        },

        /**
         * Convert Word / Excel (and PowerPoint, to show why it cannot be shown) to PDF on the server
         * and show it in the PDF preview
         * @param disk
         * @param path
         */
        openOfficeAsPdf(disk, path) {
            latestOfficeRequest += 1;
            const requestId = latestOfficeRequest;

            POST.officeToPdf(disk, path)
                .then((response) => {
                    if (requestId !== latestOfficeRequest) {
                        return;
                    }

                    // アクセス拒否などは 200 で { result: { status: 'error' } } が返り、interceptor が通知済み
                    if (response.data && response.data.result && response.data.result.status === 'error') {
                        return;
                    }

                    const [pdfDisk, pdfPath] = Array.isArray(response.data) ? response.data : [];

                    if (!pdfDisk || !pdfPath) {
                        EventBus.emit('addNotification', {
                            status: 'error',
                            message: this.lang.response.pdfError,
                        });
                        return;
                    }

                    this.$store.dispatch('fm/openPDF', {
                        disk: pdfDisk,
                        path: pdfPath,
                    });
                })
                // 失敗の理由（サイズ超過・変換失敗・時間切れ・形式対象外）は response interceptor が通知する
                .catch((error) => {
                    if (!error.response) {
                        console.error(error);
                    }
                });
        },
    },
};
