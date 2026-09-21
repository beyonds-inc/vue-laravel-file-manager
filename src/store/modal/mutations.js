/**
 * Revoke the PDF preview object URL, if any
 * @param state
 */
function releasePdfPreviewUrl(state) {
    if (state.pdfPreviewUrl) {
        URL.revokeObjectURL(state.pdfPreviewUrl);
        state.pdfPreviewUrl = null;
    }
}

export default {
    /**
     * Modal window state
     * @param state
     * @param show
     * @param modalName
     */
    setModalState(state, { show, modalName }) {
        state.showModal = show;
        state.modalName = modalName;

        if (!show) releasePdfPreviewUrl(state);
    },

    /**
     * Clear modal
     * @param state
     */
    clearModal(state) {
        state.showModal = false;
        state.modalName = null;
        releasePdfPreviewUrl(state);
    },

    /**
     * Main modal block - set height
     * @param state
     * @param height
     */
    setModalBlockHeight(state, height) {
        state.modalBlockHeight = height;
    },

    /**
     * PDF preview - set object URL
     * @param state
     * @param url
     */
    setPdfPreviewUrl(state, url) {
        releasePdfPreviewUrl(state);
        state.pdfPreviewUrl = url;
    },
};
