export default {
    /**
     * Get a list of disks
     * @param state
     * @returns {string[]}
     */
    diskList(state) {
        return Object.keys(state.disks);
    },

    /**
     * Selected disk for active manager
     * @param state
     * @returns {*}
     */
    selectedDisk(state) {
        return state[state.activeManager].selectedDisk;
    },

    /**
     * Selected directory for active manager
     * @param state
     * @returns {any}
     */
    selectedDirectory(state) {
        return state[state.activeManager].selectedDirectory;
    },

    /**
     * List of selected files and folders for the active manager
     * @param state
     * @param getters
     * @returns {*}
     */
    selectedItems(state, getters) {
        return getters[`${state.activeManager}/selectedList`];
    },

    /**
     * Inactive manager name
     * @param state
     * @returns {string}
     */
    inactiveManager(state) {
        return state.activeManager === 'left' ? 'right' : 'left';
    },

    /**
     * 選択ファイルのRW権限(acl値)
     * @param state
     * @param getters
     * @returns {boolean}
     */
    isEverySelectedItemRW(state, getters) {
        return getters[`${state.activeManager}/selectedList`].every(item => item.acl === 2);
    },
};
