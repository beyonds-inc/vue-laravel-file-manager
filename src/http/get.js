import HTTP from './axios';

export default {
    /**
     * Get configuration data from server
     * @returns {*}
     */
    initialize() {
        return HTTP.get('initialize');
    },

    /**
     * Get directories for the tree (upper level)
     * @param disk
     * @param path
     * @returns {*}
     */
    tree(disk, path) {
        return HTTP.get('tree', { params: { disk, path } });
    },

    /**
     * Select disk
     * @param disk
     * @returns {*}
     */
    selectDisk(disk) {
        return HTTP.get('select-disk', { params: { disk } });
    },

    /**
     * Get content (files and folders)
     * @param disk
     * @param path
     * @returns {*}
     */
    content(disk, path) {
        return HTTP.get('content', { params: { disk, path } });
    },

    /**
     * Item properties
     */
    /* properties(disk, path) {
      return HTTP.get('properties', { params: { disk, path } });
    }, */

    /**
     * URL
     * @param disk
     * @param path
     * @returns {*}
     */
    url(disk, path) {
        return HTTP.get('url', { params: { disk, path } });
    },

    /**
     * Get file to editing or showing
     * @param disk
     * @param path
     * @returns {*}
     */
    getFile(disk, path) {
        return HTTP.get('download', { params: { disk, path } });
    },

    /**
     * Get file - ArrayBuffer (for in-browser preview / viewing)
     *
     * Uses the dedicated `preview-download` endpoint instead of `download`
     * so that the audit trail can distinguish "閲覧（別タブで開く）" from
     * "ダウンロード". See beyonds-inc/eportal-saas Issue #785 / PR #786.
     * Only the openPDF flow (PDF preview and Word→PDF preview) uses this;
     * the 3-dot menu download keeps using `download`.
     * @param disk
     * @param path
     * @returns {*}
     */
    getFileArrayBuffer(disk, path) {
        return HTTP.get('preview-download', {
            responseType: 'arraybuffer',
            params: { disk, path },
        });
    },

    /**
     * Image thumbnail
     * @param disk
     * @param path
     * @returns {*}
     */
    thumbnail(disk, path) {
        return HTTP.get('thumbnails', {
            responseType: 'arraybuffer',
            params: { disk, path },
        });
    },

    /**
     * Image preview
     * @param disk
     * @param path
     * @return {*}
     */
    preview(disk, path) {
        return HTTP.get('preview', {
            responseType: 'arraybuffer',
            params: { disk, path },
        });
    },

    /**
     * Download file
     * @param disk
     * @param path
     * @return {*}
     */
    download(disk, path) {
        return HTTP.get('download', {
            responseType: 'arraybuffer',
            params: { disk, path },
        });
    },
};
