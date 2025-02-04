/**
 * Japanese translate
 * @type Object
 */
const ja = {
  btn: {
    about: '情報',
    back: '戻る',
    cancel: 'キャンセル',
    clear: 'クリア',
    copy: 'コピー',
    cut: '切り取り',
    delete: '削除',
    edit: '編集',
    forward: '次へ',
    folder: '新しいフォルダ',
    file: '新しいファイル',
    fullScreen: 'フルスクリーン',
    grid: 'グリッド',
    paste: '貼り付け',
    refresh: '更新',
    submit: '送信',
    table: 'テーブル',
    upload: 'アップロード',
    uploadSelect: 'ファイル選択',
    hidden: ' 隠しファイル',
    save: '保存',
  },
  clipboard: {
    actionType: 'タイプ',
    copy: 'コピー',
    cut: '切り取り',
    none: '選択なし',
    title: 'クリップボード',
  },
  contextMenu: {
    copy: 'コピー',
    cut: '切り取り',
    delete: '削除',
    download: 'ダウンロード',
    info: '選択:',
    open: '開く',
    paste: '貼り付け',
    properties: 'プロパティ',
    rename: '名前変更',
    select: '選択',
    view: '閲覧',
    zip: '圧縮',
    unzip: '解凍',
    edit: '編集',
    audioPlay: '再生',
    videoPlay: '動画再生',
    copyUrl: 'URLコピー',
  },
  info: {
    directories: 'フォルダ:',
    files: 'ファイル:',
    selected: '選択:',
    selectedSize: 'ファイルサイズ:',
    size: 'ファイルサイズ:',
  },
  manager: {
    table: {
      date: '更新日時',
      folder: 'フォルダ',
      name: '名前',
      description: '説明',
      size: 'サイズ',
      type: 'タイプ',
    },
  },
  modal: {
    about: {
      developer: '開発者',
      name: 'Laravel File Manager',
      title: '情報',
      version: 'バージョン',
    },
    delete: {
      noSelected: 'ファイルを選択してください！',
      title: '削除',
    },
    newFile: {
      fieldName: 'ファイル名',
      fieldFeedback: '同名のファイルが既に存在します！',
      title: '新しいファイル生成',
    },
    newFolder: {
      fieldName: 'フォルダ名',
      fieldFeedback: '同名のフォルダが既に存在します！',
      title: '新しいフォルダ生成',
    },
    preview: {
      title: 'プレビュー',
    },
    properties: {
      disk: 'ディスク',
      modified: '修正日時',
      name: '名前',
      path: 'パス',
      size: 'サイズ',
      title: 'プロパティ',
      type: 'タイプ',
      url: 'URL',
      access: 'アクセス権限',
      access_0: 'アクセス不可',
      access_1: '読み取り専用',
      access_2: '読み書き可能',
    },
    rename: {
      directoryExist: 'ディレクトリが既に存在します',
      fieldName: '新しい名前を入力してください',
      fieldFeedback: 'この名前は使用できません',
      fileExist: 'ファイルが既に存在します',
      title: '名前変更',
    },
    status: {
      noErrors: 'エラーはありません！',
      title: '状態',
    },
    upload: {
      ifExist: 'ファイルが既に存在する場合:',
      noSelected: 'ファイルを選択してください！',
      overwrite: '上書きします！',
      selected: '選択:',
      size: 'サイズ:',
      skip: 'スキップ',
      title: 'ファイルアップロード',
    },
    editor: {
      title: 'エディタ',
    },
    audioPlayer: {
      title: 'オーディオプレーヤー',
    },
    videoPlayer: {
      title: '動画プレーヤー',
    },
    zip: {
      title: 'アーカイブ生成',
      fieldName: 'アーカイブ名',
      fieldFeedback: 'アーカイブが既に存在します！',
    },
    unzip: {
      title: 'アーカイブ解凍',
      fieldName: 'フォルダ名',
      fieldRadioName: '解凍先:',
      fieldRadio1: '現在フォルダ',
      fieldRadio2: '新しいフォルダ',
      fieldFeedback: 'フォルダが既に存在します！',
      warning: '注意！同名の場合、ファイルが上書きされます！',
    },
    cropper: {
      title: '切り出し',
      apply: '適用',
      reset: 'リセット',
      save: '保存',
    },
  },
  notifications: {
    cutToClipboard: 'クリップボードに切り取りしました！',
    copyToClipboard: 'クリップボードにコピーしました！',
    copyUrl: 'URLをコピーしました！',
  },
  response: {
    noConfig: '設定が見つかりませんでした！',
    notFound: '見つかりませんでした！',
    diskNotFound: 'ディスクが見つかりませんでした！',
    pathNotFound: 'パスが見つかりませんでした！',
    diskSelected: 'ディスクを選択しました！',
    // files
    fileExist: 'ファイルが既に存在します！',
    fileCreated: 'ファイルを生成しました！',
    fileUpdated: 'ファイルを更新しました！',
    fileNotFound: 'ファイルが見つかりませんでした！',
    // directories
    dirExist: 'ディレクトリが既に存在します！',
    dirCreated: 'ディレクトリを生成しました！',
    dirNotFound: 'ディレクトリが見つかりませんでした',
    // actions
    uploaded: 'ファイルを全てアップロードしました！',
    notAllUploaded: 'ファイルの一部がアップロードできませんでした！',
    delNotFound: '一部項目が見つかりませんでした！',
    deleted: '削除しました！',
    renamed: '名前変更しました！',
    copied: 'コピーしました！',
    // zip
    zipError: 'アーカイブ生成にエラーが発生しました！',
    // acl
    aclError: 'アクセスが拒否されました！',
    // display pdf
    pdfError: 'プレビュー表示に失敗しました'
  },
};

export default ja;
