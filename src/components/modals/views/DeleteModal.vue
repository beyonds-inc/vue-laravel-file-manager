<template>
    <div class="modal-content fm-modal-delete">
        <div class="modal-header">
            <h5 class="modal-title">{{ lang.modal.delete.title }}</h5>
            <button type="button" class="btn-close" aria-label="Close" v-on:click="hideModal"></button>
        </div>
        <div class="modal-body">
            <div v-if="selectedItems.length">
                <selected-file-list />
            </div>
            <div v-else>
                <span class="text-danger">{{ lang.modal.delete.noSelected }}</span>
            </div>
        </div>
        <div class="modal-footer">
            <!-- 削除ボタン連打による重複リクエストを防止するため、処理中はボタンを無効化する（Issue #717） -->
            <button type="button" class="btn btn-danger" v-on:click="deleteItems" v-bind:disabled="deleting">
                {{ deleting ? lang.modal.delete.deleting || '削除中...' : lang.modal.delete.title }}
            </button>
            <button type="button" class="btn btn-light" v-on:click="hideModal" v-bind:disabled="deleting">{{ lang.btn.cancel }}</button>
        </div>
    </div>
</template>

<script>
import SelectedFileList from '../additions/SelectedFileList.vue';
import modal from '../mixins/modal';
import translate from '../../../mixins/translate';

export default {
    name: 'DeleteModal',
    mixins: [modal, translate],
    components: { SelectedFileList },
    data() {
        return {
            deleting: false,
        };
    },
    computed: {
        /**
         * Files and folders for deleting
         * @returns {*}
         */
        selectedItems() {
            return this.$store.getters['fm/selectedItems'];
        },
    },
    methods: {
        /**
         * Delete selected directories and files
         */
        deleteItems() {
            // 連打防止: 既に削除処理中の場合はリクエストを送信しない（Issue #717）
            if (this.deleting) return;
            this.deleting = true;

            // create items list for delete
            const items = this.selectedItems.map((item) => ({
                path: item.path,
                type: item.type,
            }));

            this.$store.dispatch('fm/delete', items).then(() => {
                this.hideModal();
            }).catch(() => {
                this.deleting = false;
            });
        },
    },
};
</script>
