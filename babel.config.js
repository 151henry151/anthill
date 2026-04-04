module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      [
        'babel-preset-expo',
        {
          // Metro web bundles load as classic scripts; transform `import.meta` for deps that ship ESM (e.g. package exports).
          unstable_transformImportMeta: true,
        },
      ],
    ],
  };
};
