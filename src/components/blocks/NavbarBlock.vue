<template>
    <div class="fm-navbar mb-3">
        <div class="row justify-content-between">
            <div class="col-auto d-flex ml-4">
                <div class="btn-group" role="group">
                    <button
                        type="button"
                        class="btn btn-secondary"
                        v-on:click="showModal('NewFolderModal')"
                        v-bind:title="lang.btn.folder"
                    >
                        <i class="bi bi-folder"></i>
                    </button>
                    <button
                        type="button"
                        class="btn btn-secondary"
                        v-bind:disabled="!clipboardType"
                        v-bind:title="lang.btn.paste"
                        v-on:click="paste"
                    >
                        <i class="bi bi-clipboard"></i>
                    </button>
                </div>
                <div>
                    <a
                        id="upload-link-button"
                        class="ml-4 btn back-blue bluebtn-hover shadow roundness-10"
                        role="button"
                        style="color: #fff;"
                    >
                    <span class="pre">資料アップロード</span>
                    </a>
                </div>
                <div v-if="canBatchSign" class="ml-4 fm-batch-sign-actions">
                    <button
                        type="button"
                        class="btn back-white whitebtn-hover shadow roundness-10"
                        v-on:click="toggleBatchSign"
                    >
                        {{ batchSignActive ? lang.batchSign.cancel : lang.batchSign.start }}
                    </button>
                    <button
                        v-if="batchSignActive"
                        type="button"
                        class="btn back-blue bluebtn-hover shadow roundness-10"
                        style="color: #fff"
                        v-bind:disabled="!batchSignSelectedIds.length"
                        v-on:click="submitBatchSign"
                    >
                        {{ lang.batchSign.submit.replace('{count}', batchSignSelectedIds.length) }}
                    </button>
                </div>
            </div>
        </div>
        <div v-if="canBatchSign && batchSignActive" class="alert alert-info py-2 mt-3 mb-0 fm-batch-sign-notice">
            {{ lang.batchSign.notice }}
        </div>
    </div>
</template>

<script>
import translate from '../../mixins/translate';
import EventBus from '../../emitter';
import { canBatchSign } from '../../batchSign';

export default {
    name: 'NavbarBlock',
    mixins: [translate],
    data() {
        return {
            isEditor: Number(isEditor),
            canBatchSign: canBatchSign(),
        };
    },
    computed: {
        /**
         * 一括署名の選択モード中か
         * @returns {boolean}
         */
        batchSignActive() {
            return this.$store.state.fm.batchSign.active;
        },

        /**
         * 一括署名で選んでいるファイルの material_id
         * @returns {number[]}
         */
        batchSignSelectedIds() {
            return this.$store.getters['fm/batchSignSelectedIds'];
        },

        /**
         * 表示しているディスクとフォルダ
         * @returns {string}
         */
        currentLocation() {
            return `${this.$store.getters['fm/selectedDisk']}:${this.$store.getters['fm/selectedDirectory']}`;
        },

        /**
         * Active manager name
         * @returns {any}
         */
        activeManager() {
            return this.$store.state.fm.activeManager;
        },

        /**
         * Clipboard - action type
         * @returns {null}
         */
        clipboardType() {
            return this.$store.state.fm.clipboard.type;
        },
    },
    watch: {
        /**
         * 一括署名は同じフォルダのファイルだけのため、別のフォルダを開いたら選択を空にする
         */
        currentLocation() {
            this.$store.commit('fm/clearBatchSignSelection');
        },
    },
    methods: {
        /**
         * 一括署名の選択モードを始める・解除する
         */
        toggleBatchSign() {
            this.$store.commit('fm/setBatchSignMode', !this.batchSignActive);
        },

        /**
         * 選んだファイルで、ePortal の一括署名画面へ移る
         */
        submitBatchSign() {
            const ids = this.batchSignSelectedIds;
            if (!ids.length) return;

            const baseUrl = window.actionUrls ? window.actionUrls.batchSignature : null;
            if (!baseUrl) {
                EventBus.emit('addNotification', {
                    status: 'error',
                    message: this.lang.batchSign.urlError,
                });
                return;
            }

            const query = ids.map((id) => `material_ids[]=${encodeURIComponent(id)}`).join('&');
            window.location.href = `${baseUrl}?${query}`;
        },

        /**
         * Paste
         */
        paste() {
            this.$store.dispatch('fm/paste');
        },
        /**
         * Show modal window
         * @param modalName
         */
        showModal(modalName) {
            // show selected modal
            this.$store.commit('fm/modal/setModalState', {
                modalName,
                show: true,
            });
        },
    },
};
</script>

<style lang="scss">
.fm-navbar {
    flex: 0 0 auto;

    .fm-batch-sign-actions {
        display: flex;
        gap: 0.5rem;
    }
}
</style>
