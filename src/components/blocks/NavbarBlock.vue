<template>
    <div class="fm-navbar mb-3">
        <div class="row justify-content-between">
            <div class="col-auto">
                <div class="btn-group" role="group">
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
            </div>
        </div>
    </div>
</template>

<script>
import translate from '../../mixins/translate';

export default {
    name: 'NavbarBlock',
    mixins: [translate],
    computed: {
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
    methods: {
        /**
         * Paste
         */
        paste() {
            this.$store.dispatch('fm/paste');
        },
    },
};
</script>

<style lang="scss">
.fm-navbar {
    flex: 0 0 auto;
}
</style>
