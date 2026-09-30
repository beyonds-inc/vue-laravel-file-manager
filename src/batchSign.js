/**
 * 一括署名の選択モード（eportal-saas #821）で使う共通の判定
 */

// ePortal 側（config('econsent.batch_sign.max_files')）の既定値
const DEFAULT_MAX_FILES = 10;

/**
 * 選択モードで表示・選択できるファイルか（施設スタッフがアップロードした未署名の PDF）
 * uploader_role は ePortal の一覧 API が返す、現在の試験でのアップロード者のロール。
 * 署名欄の有無や PDF を読めるかは一覧では調べず、ePortal の一括署名画面で判定する
 * @param file
 * @returns {boolean}
 */
export function isBatchSignable(file) {
    return (
        Boolean(file.material_id) &&
        !file.is_signed &&
        file.uploader_role === 'medical' &&
        typeof file.extension === 'string' &&
        file.extension.toLowerCase() === 'pdf'
    );
}

/**
 * 一度に選択できる件数（ePortal の blade が batchSignMaxFiles で渡す）
 * @returns {number}
 */
export function batchSignMaxFiles() {
    const max = Number(window.batchSignMaxFiles);

    return Number.isInteger(max) && max > 0 ? max : DEFAULT_MAX_FILES;
}

/**
 * 一括署名のボタンを出すか（医師のみ。ePortal の blade が isDoctor で渡す）
 * @returns {boolean}
 */
export function canBatchSign() {
    return window.isDoctor !== undefined && window.isDoctor === '1';
}
