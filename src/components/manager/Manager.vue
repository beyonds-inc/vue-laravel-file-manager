<template>
    <div class="fm-content d-flex flex-column">
        <disk-list v-bind:manager="manager" />
        <bread-crumb v-bind:manager="manager" />
        <div class="fm-content-body">
            <!-- 一括署名の選択モードはテーブル表示でだけ行う -->
            <table-view v-if="viewType === 'table' || batchSignActive" v-bind:manager="manager" />
            <grid-view v-else v-bind:manager="manager" />
        </div>
    </div>
</template>

<script>
// Components
import DiskList from './DiskList.vue';
import BreadCrumb from './BreadCrumb.vue';
import TableView from './TableView.vue';
import GridView from './GridView.vue';

export default {
    name: 'Manager',
    components: {
        DiskList,
        BreadCrumb,
        TableView,
        GridView,
    },
    props: {
        manager: { type: String, required: true },
    },
    computed: {
        /**
         * view type - grid or table
         * @returns {any}
         */
        viewType() {
            return this.$store.state.fm[this.manager].viewType;
        },

        /**
         * 一括署名の選択モード中か
         * @returns {boolean}
         */
        batchSignActive() {
            return this.$store.state.fm.batchSign.active;
        },
    },
};
</script>

<style lang="scss">
.fm-content {
    padding-left: 1rem;

    .fm-content-body {
        overflow: auto;
    }
}
</style>
