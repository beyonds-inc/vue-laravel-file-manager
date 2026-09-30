import HTTP from './axios';

export default {
    /**
     * Create new file
     * @param disk
     * @param path
     * @param name
     * @returns {Promise<AxiosResponse<any>>}
     */
    createFile(disk, path, name) {
        return HTTP.post('create-file', { disk, path, name });
    },

    /**
     * Update file
     * @param formData
     * @returns {*}
     */
    updateFile(formData) {
        return HTTP.post('update-file', formData);
    },

    /**
     * Create new directory
     * @param data
     * @returns {*}
     */
    createDirectory(data) {
        return HTTP.post('create-directory', data);
    },

    /**
     * Upload file
     * @param data
     * @param config
     * @returns {Promise<AxiosResponse<any>>}
     */
    upload(data, config) {
        return HTTP.post('upload', data, config);
    },

    /**
     * Delete selected items
     * @param data
     * @returns {*}
     */
    delete(data) {
        return HTTP.post('delete', data);
    },

    /**
     * Rename file or folder
     * @param data
     * @returns {*}
     */
    rename(data) {
        return HTTP.post('rename', data);
    },

    /**
     * Copy / Cut files and folders
     * @param data
     * @returns {*}
     */
    paste(data) {
        return HTTP.post('paste', data);
    },

    /**
     * Zip
     * @param data
     * @returns {*}
     */
    zip(data) {
        return HTTP.post('zip', data);
    },

    /**
     * Unzip
     * @returns {*}
     * @param data
     */
    unzip(data) {
        return HTTP.post('unzip', data);
    },

    /**
     * Convert Word / Excel to PDF for the in-portal preview (eportal-saas #824)
     * The reason of a failure (unsupported type, size, timeout) is shown by the response interceptor.
     * @param disk
     * @param path
     * @returns {*}
     */
    officeToPdf(disk, path) {
        const formData = new FormData();
        formData.append('disk', disk);
        formData.append('path', path);

        return HTTP.post('word-to-pdf/convert', formData);
    },
};
