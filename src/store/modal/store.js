import mutations from './mutations';

export default {
    namespaced: true,
    state() {
        return {
            // modal window
            showModal: false,

            // modal name
            modalName: null,

            // main modal block height
            modalBlockHeight: 0,

            // object URL of the PDF blob shown in PdfPreviewModal
            pdfPreviewUrl: null,
        };
    },
    mutations,
};
