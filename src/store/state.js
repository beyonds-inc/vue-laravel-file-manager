export default {
    /**
     * Active manager
     * left or right
     * default: left
     */
    activeManager: 'left',

    /**
     * Clipboard
     * Operation type - copy || cut
     */
    clipboard: {
        type: null,
        disk: null,
        directories: [],
        files: [],
    },

    // available disks
    disks: [],

    // file callback for ckeditor, ...
    fileCallback: null,

    // full screen mode
    fullScreen: false,

    // 一括署名の選択モード（eportal-saas #821）。selectedIds は選んだファイルの material_id
    batchSign: {
        active: false,
        selectedIds: [],
    },
};
