/**
 * Rules for context menu items (show/hide)
 * {name}Rule
 */
export default {
    methods: {
        /**
         * Open - menu item status - show or hide
         * @returns {boolean}
         */
        openRule() {
            return !this.multiSelect && this.firstItemType === 'dir';
        },

        /**
         * Play audio - menu item status - show or hide
         * @returns {boolean}
         */
        audioPlayRule() {
            return (
                this.selectedItems.every((elem) => elem.type === 'file') &&
                this.selectedItems.every((elem) => this.canAudioPlay(elem.extension))
            );
        },

        /**
         * Play video - menu item status - show or hide
         * @returns {boolean}
         */
        videoPlayRule() {
            return !this.multiSelect && this.canVideoPlay(this.selectedItems[0].extension);
        },

        /**
         * View - menu item status - show or hide
         * @returns {boolean|*}
         */
        viewRule() {
            return !this.multiSelect && this.firstItemType === 'file' && this.canView(this.selectedItems[0].extension);
        },

        /**
         * Edit - menu item status - show or hide
         * @returns {boolean|*}
         */
        editRule() {
            // return !this.multiSelect && this.firstItemType === 'file' && this.canEdit(this.selectedItems[0].extension) && this.$store.getters['fm/isEverySelectedItemRW'];
            return false;
        },

        /**
         * Select - menu item status - show or hide
         * @returns {boolean|null}
         */
        selectRule() {
            return !this.multiSelect && this.firstItemType === 'file' && this.$store.state.fm.fileCallback;
        },

        /**
         * Download - menu item status - show or hide
         * @returns {boolean}
         */
        downloadRule() {
            // return !this.multiSelect && this.firstItemType === 'file';
            // ファイルを複数選択してもダウンロードできるように変更
            return this.selectedItems.every((elem) => elem.type === 'file');
        },

        /**
         * Copy URL - menu item status - show or hide
         * @returns {boolean}
         */
        copyUrlRule() {
            return !this.multiSelect && this.selectedItems[0].type === 'file';
        },

        /**
         * Copy - menu item status - show or hide
         * @returns {boolean}
         */
        copyRule() {
            // return true;
            return false;
        },

        /**
         * Cut - menu item status - show or hide
         * @returns {boolean}
         */
        cutRule() {
            return this.$store.getters['fm/isEverySelectedItemRW'] && this.selectedItems.every((elem) => elem.type === 'file');
            // return false;
        },

        /**
         * Rename - menu item status - show or hide
         * @returns {boolean}
         */
        renameRule() {
            // return !this.multiSelect && this.$store.getters['fm/isEverySelectedItemRW'];
            return false;
        },

        /**
         * Paste - menu item status - show or hide
         * @returns {boolean}
         */
        pasteRule() {
            // return !!this.$store.state.fm.clipboard.type && this.$store.getters['fm/isEverySelectedItemRW'];
            return false;
        },

        /**
         * Zip - menu item status - show or hide
         * @returns {boolean}
         */
        zipRule() {
            // return this.selectedDiskDriver === 'local' && this.$store.getters['fm/isEverySelectedItemRW'];
            return false;
        },

        /**
         * Unzip - menu item status - show or hide
         * @returns {boolean}
         */
        unzipRule() {
            // return (
            //     this.selectedDiskDriver === 'local' &&
            //     !this.multiSelect &&
            //     this.firstItemType === 'file' &&
            //     this.isZip(this.selectedItems[0].extension) &&
            //     this.$store.getters['fm/isEverySelectedItemRW']
            // );
            return false;
        },

        /**
         * Delete - menu item status - show or hide
         * @returns {boolean}
         */
        deleteRule() {
            const isEditor = role === 'editor';
            // forbid medical users from deleting folders
            if (!this.selectedItems.every((elem) => elem.type === 'file') && !isEditor) {
                return false;
            }
            return this.$store.getters['fm/isEverySelectedItemRW'];
        },

        /**
         * Properties - menu item status - show or hide
         * @returns {boolean}
         */
        propertiesRule() {
            // return !this.multiSelect;
            return false;
        },
    },
};
