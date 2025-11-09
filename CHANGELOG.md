<a name="0.2.3"></a>
## [2.5.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.5.0...v2.5.1) (2025-11-09)


### Bug Fixes

* respect user-configured window options on buffer delete ([#497](https://github.com/shortcuts/no-neck-pain.nvim/issues/497)) ([#498](https://github.com/shortcuts/no-neck-pain.nvim/issues/498)) ([7ed79dc](https://github.com/shortcuts/no-neck-pain.nvim/commit/7ed79dc86ad9293a41eb39d6e207ff501f2e6d6d))

## [2.5.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.4.7...v2.5.0) (2025-10-03)


### Features

* **highlight:** create namespace and empty groups by default ([#495](https://github.com/shortcuts/no-neck-pain.nvim/issues/495)) ([9efbc12](https://github.com/shortcuts/no-neck-pain.nvim/commit/9efbc12c5707ef81f614ffb36f11ea7a78652bbc))

## [2.4.7](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.4.6...v2.4.7) (2025-09-13)


### Bug Fixes

* **mappings:** race conditions ([#492](https://github.com/shortcuts/no-neck-pain.nvim/issues/492)) ([31adc88](https://github.com/shortcuts/no-neck-pain.nvim/commit/31adc8887b7cee6c067634d40761905feb194d35))

## [2.4.6](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.4.5...v2.4.6) (2025-08-25)


### Bug Fixes

* **scratchPad:** restore focus when disabling ([#489](https://github.com/shortcuts/no-neck-pain.nvim/issues/489)) ([658ea7d](https://github.com/shortcuts/no-neck-pain.nvim/commit/658ea7daffede1543b9846f8128a205b96a4786b))

## [2.4.5](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.4.4...v2.4.5) (2025-06-02)


### Bug Fixes

* do not resize vsplits ([#474](https://github.com/shortcuts/no-neck-pain.nvim/issues/474)) ([3be8d37](https://github.com/shortcuts/no-neck-pain.nvim/commit/3be8d375c36fba9e6376e0c4a3043310c2e021d7))
* subtract `integration_width` first to calculate the side buffer width ([#472](https://github.com/shortcuts/no-neck-pain.nvim/issues/472)) ([cf76573](https://github.com/shortcuts/no-neck-pain.nvim/commit/cf76573a806a4986d2ea62aae5dca500726df767))

## [2.4.4](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.4.3...v2.4.4) (2025-06-01)


### Bug Fixes

* prevent unexpected error on resize for unknown tabs ([#475](https://github.com/shortcuts/no-neck-pain.nvim/issues/475)) ([26d18f2](https://github.com/shortcuts/no-neck-pain.nvim/commit/26d18f26f3a6ea038dd7604f23b6f7155a2c513f))

## [2.4.3](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.4.2...v2.4.3) (2025-05-29)


### Bug Fixes

* properly compute remaining width after integrations ([#469](https://github.com/shortcuts/no-neck-pain.nvim/issues/469)) ([4367884](https://github.com/shortcuts/no-neck-pain.nvim/commit/43678849d6c9a101b58a307d4a26f58681f15b19))

## [2.4.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.4.1...v2.4.2) (2025-05-14)


### Bug Fixes

* do not resize integration windows ([#466](https://github.com/shortcuts/no-neck-pain.nvim/issues/466)) ([7d83f3e](https://github.com/shortcuts/no-neck-pain.nvim/commit/7d83f3ef1c29c0401d12ea3bcd1675399b3e53c0))

## [2.4.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.4.0...v2.4.1) (2025-05-01)


### Bug Fixes

* npe on dashboard's filetypes ([#463](https://github.com/shortcuts/no-neck-pain.nvim/issues/463)) ([33a19ae](https://github.com/shortcuts/no-neck-pain.nvim/commit/33a19ae4c4e79df1ed13c56c64c371f0e1a51d65))
* properly reset window options on `bd` ([#465](https://github.com/shortcuts/no-neck-pain.nvim/issues/465)) ([2299b41](https://github.com/shortcuts/no-neck-pain.nvim/commit/2299b41c086369e4636daa533ebd7ecb82eef3e6))

## [2.4.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.3.0...v2.4.0) (2025-04-24)


### Features

* allow safe `enableOnVimEnter` ([#456](https://github.com/shortcuts/no-neck-pain.nvim/issues/456)) ([4dc80b2](https://github.com/shortcuts/no-neck-pain.nvim/commit/4dc80b2d55aef6c6486514f9896351164d531b4d))


### Bug Fixes

* allow custom dashboards ([#461](https://github.com/shortcuts/no-neck-pain.nvim/issues/461)) ([289bc6d](https://github.com/shortcuts/no-neck-pain.nvim/commit/289bc6d5693feff6b952fc534cbfc8f00c44545d))

## [2.3.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.2.0...v2.3.0) (2025-04-15)


### Features

* provide pre/post enable and pre/post disable callback methods ([#451](https://github.com/shortcuts/no-neck-pain.nvim/issues/451)) ([c713b1f](https://github.com/shortcuts/no-neck-pain.nvim/commit/c713b1fbd1114a27cbba68daa553418c695b10e6))

## [2.2.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.1.5...v2.2.0) (2025-03-07)


### Features

* better dashboard support ([#442](https://github.com/shortcuts/no-neck-pain.nvim/issues/442)) ([c1782a2](https://github.com/shortcuts/no-neck-pain.nvim/commit/c1782a24f5d55cee7ee39984c25a381580722dc3))

## [2.1.5](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.1.4...v2.1.5) (2025-01-23)


### Bug Fixes

* 'Invalid window id ...' error when restoring a session saved with an invisible Scratch Window ([#430](https://github.com/shortcuts/no-neck-pain.nvim/issues/430)) ([#431](https://github.com/shortcuts/no-neck-pain.nvim/issues/431)) ([2ca9857](https://github.com/shortcuts/no-neck-pain.nvim/commit/2ca98574e04a7ac68da6051626e661c386331ac8))
* **autocmds:** BufWinEnter race condition? ([#434](https://github.com/shortcuts/no-neck-pain.nvim/issues/434)) ([3fc4642](https://github.com/shortcuts/no-neck-pain.nvim/commit/3fc4642702a3d736196977e948800a6aff5f7262))

## [2.1.4](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.1.3...v2.1.4) (2025-01-16)


### Bug Fixes

* **enableOnVimEnter:** prevent flicker on enter ([#429](https://github.com/shortcuts/no-neck-pain.nvim/issues/429)) ([36979b5](https://github.com/shortcuts/no-neck-pain.nvim/commit/36979b57535da51f40bb4deef16192333e92f2aa))

## [2.1.3](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.1.2...v2.1.3) (2024-11-30)


### Bug Fixes

* do not reroute to invalid (deleted) window ([#423](https://github.com/shortcuts/no-neck-pain.nvim/issues/423)) ([b89b557](https://github.com/shortcuts/no-neck-pain.nvim/commit/b89b55706d7e5ff8ab6700a76b23835aeecb9052))

## [2.1.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.1.1...v2.1.2) (2024-11-29)


### Bug Fixes

* prevent non-focusable windows from being focused ([#421](https://github.com/shortcuts/no-neck-pain.nvim/issues/421)) ([581e715](https://github.com/shortcuts/no-neck-pain.nvim/commit/581e71577c01ee622fc272bff56ee40017bb24b8))

## [2.1.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.1.0...v2.1.1) (2024-11-28)


### Bug Fixes

* do not skip relative windows on re-route ([#418](https://github.com/shortcuts/no-neck-pain.nvim/issues/418)) ([6943bc9](https://github.com/shortcuts/no-neck-pain.nvim/commit/6943bc96ae5816e466e38651521d8b92ee566601))

## [2.1.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.0.6...v2.1.0) (2024-11-26)


### Features

* **integrations:** support snacks.nvim ([#416](https://github.com/shortcuts/no-neck-pain.nvim/issues/416)) ([b0c7a3a](https://github.com/shortcuts/no-neck-pain.nvim/commit/b0c7a3ab099fe53b797d0a414b23778d02082c2c))

## [2.0.6](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.0.5...v2.0.6) (2024-10-04)


### Bug Fixes

* **splits:** check curr id before rerouting ([#409](https://github.com/shortcuts/no-neck-pain.nvim/issues/409)) ([e3d0d8b](https://github.com/shortcuts/no-neck-pain.nvim/commit/e3d0d8b1a9118c1e899ded1eb1a1558f794a3a8f))

## [2.0.5](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.0.4...v2.0.5) (2024-09-27)


### Bug Fixes

* **tabs:** prevent wrong resize on tabnew ([#404](https://github.com/shortcuts/no-neck-pain.nvim/issues/404)) ([f4c1b54](https://github.com/shortcuts/no-neck-pain.nvim/commit/f4c1b54b6d335e612f201c7fbf2e4447ef3790ac))

## [2.0.4](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.0.3...v2.0.4) (2024-09-27)


### Bug Fixes

* **integrations:** do not assert position ([#401](https://github.com/shortcuts/no-neck-pain.nvim/issues/401)) ([af83256](https://github.com/shortcuts/no-neck-pain.nvim/commit/af832565cbd467e65c2ec3ea1d8b60f1fb53d8c5))

## [2.0.3](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.0.2...v2.0.3) (2024-09-23)


### Bug Fixes

* **buffers:** compute width before creating sides ([#397](https://github.com/shortcuts/no-neck-pain.nvim/issues/397)) ([3f69467](https://github.com/shortcuts/no-neck-pain.nvim/commit/3f694679fb59611677a226d0c4a534e2348050c2))

## [2.0.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.0.1...v2.0.2) (2024-09-17)


### Bug Fixes

* **autocmds:** prevent stucked focus on skip enter ([#394](https://github.com/shortcuts/no-neck-pain.nvim/issues/394)) ([974216f](https://github.com/shortcuts/no-neck-pain.nvim/commit/974216f8d143ac1a74e70586bea6b1aac00eac9a))

## [2.0.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v2.0.0...v2.0.1) (2024-09-09)


### Bug Fixes

* **split:** vsplits integration resize inconsistencies ([#391](https://github.com/shortcuts/no-neck-pain.nvim/issues/391)) ([09736f4](https://github.com/shortcuts/no-neck-pain.nvim/commit/09736f4a1d11c2746dc6538986a2ded097e4fbdd))

## [2.0.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.16.1...v2.0.0) (2024-09-03)

There should be no breaking changes in this new major, however a lot of behavioral changes (for the better!). Thanks for using the plugin :)

### ⚠ BREAKING CHANGES

* **next:** 2.0.0 major version ([#384](https://github.com/shortcuts/no-neck-pain.nvim/issues/384))

### Features

* **next:** 2.0.0 major version ([#384](https://github.com/shortcuts/no-neck-pain.nvim/issues/384)) ([63c5094](https://github.com/shortcuts/no-neck-pain.nvim/commit/63c5094090521354ad8b69a0a0627d4552c56f2b))

## [1.16.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.16.0...v1.16.1) (2024-09-01)


### Bug Fixes

* default filetype not set ([#386](https://github.com/shortcuts/no-neck-pain.nvim/issues/386)) ([c42db61](https://github.com/shortcuts/no-neck-pain.nvim/commit/c42db61979a5e7cea5bbda8adc8ec879b231d663))

## [1.16.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.15.0...v1.16.0) (2024-08-29)


### Features

* add mini.starter dashboard to constants ([#377](https://github.com/shortcuts/no-neck-pain.nvim/issues/377)) ([d8168ac](https://github.com/shortcuts/no-neck-pain.nvim/commit/d8168ac45f1aed39ca9c9d85146d3408a9163191))

## [1.15.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.14.1...v1.15.0) (2024-08-29)


### Features

* **splits:** leverage winlayout ([#375](https://github.com/shortcuts/no-neck-pain.nvim/issues/375)) ([ba74759](https://github.com/shortcuts/no-neck-pain.nvim/commit/ba7475920e0de811768728589f6c1c7df156c803))


### Bug Fixes

* inconsistent resizes on vsplits ([#380](https://github.com/shortcuts/no-neck-pain.nvim/issues/380)) ([af5c9bc](https://github.com/shortcuts/no-neck-pain.nvim/commit/af5c9bca059bf2aec6a3046e7507e5bd8dbeb3c0))

## [1.14.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.14.0...v1.14.1) (2024-06-26)


### Bug Fixes

* **tabs:** do not close if tabs are left ([#371](https://github.com/shortcuts/no-neck-pain.nvim/issues/371)) ([22ba867](https://github.com/shortcuts/no-neck-pain.nvim/commit/22ba86731a85334d99e2a81e5ecb0966a7ff08d2))

## [1.14.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.13.0...v1.14.0) (2024-05-26)


### Features

* **disable:** warns with better ux when trying to leave ([#364](https://github.com/shortcuts/no-neck-pain.nvim/issues/364)) ([0c19c54](https://github.com/shortcuts/no-neck-pain.nvim/commit/0c19c5460f77770687817e7f935e8f510ab877f1))

## [1.13.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.12.3...v1.13.0) (2024-05-19)


### Features

* **integrations:** support aerial.nvim ([#360](https://github.com/shortcuts/no-neck-pain.nvim/issues/360)) ([75f6a53](https://github.com/shortcuts/no-neck-pain.nvim/commit/75f6a53eec03907e3c04f22235c80b61c1819eb3))

## [1.12.3](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.12.2...v1.12.3) (2024-05-18)


### Bug Fixes

* **disable:** prevent blocked quit with relative windows ([#354](https://github.com/shortcuts/no-neck-pain.nvim/issues/354)) ([d80b5a8](https://github.com/shortcuts/no-neck-pain.nvim/commit/d80b5a8d126f01416407bfc9de2c26cedc8f9681))

## [1.12.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.12.1...v1.12.2) (2024-05-15)


### Bug Fixes

* **autocmds:** do not force close unsaved buffers ([#349](https://github.com/shortcuts/no-neck-pain.nvim/issues/349)) ([9a529ec](https://github.com/shortcuts/no-neck-pain.nvim/commit/9a529ecdee2b5101ec565b905fc012194e09cc72))

## [1.12.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.12.0...v1.12.1) (2024-03-29)


### Bug Fixes

* **autocmds:** wrong registered group ([#338](https://github.com/shortcuts/no-neck-pain.nvim/issues/338)) ([59f5c1a](https://github.com/shortcuts/no-neck-pain.nvim/commit/59f5c1a550bc0558c98727aefd8eb45336f27870))

## [1.12.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.11.1...v1.12.0) (2024-03-28)


### Features

* **integrations:** support outline.nvim ([#335](https://github.com/shortcuts/no-neck-pain.nvim/issues/335)) ([aec69e6](https://github.com/shortcuts/no-neck-pain.nvim/commit/aec69e60330442a32dbd663a5cfea48a68f2c519))

## [1.11.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.11.0...v1.11.1) (2024-03-27)


### Bug Fixes

* **scratchPad:** option defined in wrong order ([#333](https://github.com/shortcuts/no-neck-pain.nvim/issues/333)) ([0e27d1f](https://github.com/shortcuts/no-neck-pain.nvim/commit/0e27d1f5f05a3df79037352fe021f5c5001e661b))

## [1.11.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.10.2...v1.11.0) (2024-03-27)


### Features

* **scratchPad:** provide `pathToFile` option ([#332](https://github.com/shortcuts/no-neck-pain.nvim/issues/332)) ([9a8d96d](https://github.com/shortcuts/no-neck-pain.nvim/commit/9a8d96dbf30611e033a828298f7e811ca4c29ed3))


### Bug Fixes

* **autocmds:** better state check for scratchpads ([#327](https://github.com/shortcuts/no-neck-pain.nvim/issues/327)) ([a54ffe9](https://github.com/shortcuts/no-neck-pain.nvim/commit/a54ffe9c61a30b8351fb3686cf83cf5840ddeaf0))

## [1.10.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.10.1...v1.10.2) (2024-03-24)


### Bug Fixes

* **autocmds:** allow registering rerouting for toggle option ([#324](https://github.com/shortcuts/no-neck-pain.nvim/issues/324)) ([28f433c](https://github.com/shortcuts/no-neck-pain.nvim/commit/28f433c93da9d360f7f930a9052770af26ab895a))
* **autocmds:** clear after debounce ([#326](https://github.com/shortcuts/no-neck-pain.nvim/issues/326)) ([1befb94](https://github.com/shortcuts/no-neck-pain.nvim/commit/1befb94faaebe8f85176fb31fe83f0bc47b162cd))

## [1.10.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.10.0...v1.10.1) (2024-03-24)


### Bug Fixes

* **autocmds:** buffer rerouting and with scratchPads ([#322](https://github.com/shortcuts/no-neck-pain.nvim/issues/322)) ([c053da4](https://github.com/shortcuts/no-neck-pain.nvim/commit/c053da46343e38e79239dbf508d8baca3bee59f4))

## [1.10.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.9.0...v1.10.0) (2024-03-23)


### Features

* **api:** add autocmd to skip entering side buffer ([#321](https://github.com/shortcuts/no-neck-pain.nvim/issues/321)) ([5539239](https://github.com/shortcuts/no-neck-pain.nvim/commit/55392392a1852ab21fd6e44084103ea2e476de96))
* **integrations:** skip redraw on every calls ([#319](https://github.com/shortcuts/no-neck-pain.nvim/issues/319)) ([96afa97](https://github.com/shortcuts/no-neck-pain.nvim/commit/96afa978e39e45290c37a087bb40a1862dc2896f))

## [1.9.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.8.3...v1.9.0) (2024-03-17)

### Features

* **integrations:** support alpha.nvim ([#317](https://github.com/shortcuts/no-neck-pain.nvim/issues/317)) ([73b4e17](https://github.com/shortcuts/no-neck-pain.nvim/commit/73b4e17a7f052d879f1b0b8fafadcbc3b17f2396))

## [1.8.3](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.8.2...v1.8.3) (2024-03-13)


### Bug Fixes

* flickering because of debounce ([#311](https://github.com/shortcuts/no-neck-pain.nvim/issues/311)) ([4e3b4f3](https://github.com/shortcuts/no-neck-pain.nvim/commit/4e3b4f386287154fdab0c5f61d9692e699b56674))
* **integrations:** properly reopen tsplayground ([#313](https://github.com/shortcuts/no-neck-pain.nvim/issues/313)) ([429f553](https://github.com/shortcuts/no-neck-pain.nvim/commit/429f5534b777192fad6a06df3a19d7392d185ab0))

## [1.8.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.8.1...v1.8.2) (2024-03-12)


### Bug Fixes

* **integrations:** faster debounce and resize padding ([#307](https://github.com/shortcuts/no-neck-pain.nvim/issues/307)) ([0861ca9](https://github.com/shortcuts/no-neck-pain.nvim/commit/0861ca9401fed248981b807966e896f5c8b1ff5e))

## [1.8.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.8.0...v1.8.1) (2024-02-05)


### Bug Fixes

* **scratchPas:** set default options at config init ([#301](https://github.com/shortcuts/no-neck-pain.nvim/issues/301)) ([90a281e](https://github.com/shortcuts/no-neck-pain.nvim/commit/90a281ed5c6658a950368584ed2d6639345fbe65))

## [1.8.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.7.2...v1.8.0) (2024-02-04)


### Features

* **theme:** add StatusLine and StatusLineNC highlights to the group ([#294](https://github.com/shortcuts/no-neck-pain.nvim/issues/294)) ([3005aec](https://github.com/shortcuts/no-neck-pain.nvim/commit/3005aecdd3fabc13a170357d5347a6cc2199ab26))


### Bug Fixes

* buffer options order ([#300](https://github.com/shortcuts/no-neck-pain.nvim/issues/300)) ([fdbd8bf](https://github.com/shortcuts/no-neck-pain.nvim/commit/fdbd8bf4790389fd9d97aa1b14c6c5488bfb5c87))

## [1.7.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.7.1...v1.7.2) (2024-01-24)


### Bug Fixes

* **scratchPad:** properly forward buffer/window options ([#291](https://github.com/shortcuts/no-neck-pain.nvim/issues/291)) ([94fc9de](https://github.com/shortcuts/no-neck-pain.nvim/commit/94fc9de2f02f737d39bb78ff731f323e8e51b9a3))

## [1.7.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.7.0...v1.7.1) (2023-12-24)


### Bug Fixes

* **hl:** prevent wrong bg and text colors after `:bd` ([#287](https://github.com/shortcuts/no-neck-pain.nvim/issues/287)) ([b317682](https://github.com/shortcuts/no-neck-pain.nvim/commit/b317682259a5c5b78210ff7f2e1d1362bf48b5e9))

## [1.7.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.6.3...v1.7.0) (2023-12-13)


### Features

* **api:** support :bdelete ([#281](https://github.com/shortcuts/no-neck-pain.nvim/issues/281)) ([ba409c3](https://github.com/shortcuts/no-neck-pain.nvim/commit/ba409c31b8d8ae9a36f560f38cfb6b718acfa6ea))


### Bug Fixes

* **hl:** prevent global highlights ([#283](https://github.com/shortcuts/no-neck-pain.nvim/issues/283)) ([938d8ea](https://github.com/shortcuts/no-neck-pain.nvim/commit/938d8ea1b13f6cea08dcc2d031acdd0ff3a3fe71))

## [1.6.3](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.6.2...v1.6.3) (2023-12-01)


### Bug Fixes

* **tabs:** prevent unsynchronized state on toggle ([#274](https://github.com/shortcuts/no-neck-pain.nvim/issues/274)) ([55fffbc](https://github.com/shortcuts/no-neck-pain.nvim/commit/55fffbc61912682c92069ca5757547f988f10d26))

## [1.6.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.6.1...v1.6.2) (2023-11-29)


### Bug Fixes

* **tabs:** prevent wrong activeTab index ([#271](https://github.com/shortcuts/no-neck-pain.nvim/issues/271)) ([bda33be](https://github.com/shortcuts/no-neck-pain.nvim/commit/bda33bee32dae1bdfdf3643273421a33f350ffc7))

## [1.6.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.6.0...v1.6.1) (2023-11-28)


### Bug Fixes

* **tabs:** prevent unsynced state in tab switchs ([#269](https://github.com/shortcuts/no-neck-pain.nvim/issues/269)) ([2afc30d](https://github.com/shortcuts/no-neck-pain.nvim/commit/2afc30d8ec23000c4f830310661f63ee3b581a42))

## [1.6.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.5.0...v1.6.0) (2023-11-26)


### Features

* **api:** add commands to toggle sides ([#266](https://github.com/shortcuts/no-neck-pain.nvim/issues/266)) ([0a14fbb](https://github.com/shortcuts/no-neck-pain.nvim/commit/0a14fbb9a88ccbb8fd54491d89f7aee038975a00))

## [1.5.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.4.1...v1.5.0) (2023-11-25)


### Features

* **mappins:** allow custom values for widthUp and widthDown ([#264](https://github.com/shortcuts/no-neck-pain.nvim/issues/264)) ([47414ce](https://github.com/shortcuts/no-neck-pain.nvim/commit/47414ce5f3eba996c501492d70da65d4c3710b53))

## [1.4.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.4.0...v1.4.1) (2023-11-10)


### Bug Fixes

* **event:** prevent unwanted resize ([#255](https://github.com/shortcuts/no-neck-pain.nvim/issues/255)) ([9ba2907](https://github.com/shortcuts/no-neck-pain.nvim/commit/9ba2907f76ab42ac8f1a8ba80e39bd383d58ae1e))
* **resize:** do not skip `VimResized` event ([#257](https://github.com/shortcuts/no-neck-pain.nvim/issues/257)) ([16c0e1a](https://github.com/shortcuts/no-neck-pain.nvim/commit/16c0e1a5d150ff274aa84349c58d12cdd5321157))

## [1.4.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.3.0...v1.4.0) (2023-10-24)


### Features

* rewrite no-neck-pain ([#250](https://github.com/shortcuts/no-neck-pain.nvim/issues/250)) ([7a16c73](https://github.com/shortcuts/no-neck-pain.nvim/commit/7a16c73d3f0142746a3f7346bf73e0e761c91dd5))

## [1.3.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.2.3...v1.3.0) (2023-10-14)


### Features

* support neotest ([#247](https://github.com/shortcuts/no-neck-pain.nvim/issues/247)) ([9f2e39c](https://github.com/shortcuts/no-neck-pain.nvim/commit/9f2e39c6877ca679275084597e2d79bb42a746ef))


### Bug Fixes

* **internal:** prevent unsync state ([#244](https://github.com/shortcuts/no-neck-pain.nvim/issues/244)) ([038b924](https://github.com/shortcuts/no-neck-pain.nvim/commit/038b924e167ac45062c7e584e94e57d76683ca7f))

## [1.2.3](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.2.2...v1.2.3) (2023-06-24)


### Bug Fixes

* prevent error on augroup deletion ([#233](https://github.com/shortcuts/no-neck-pain.nvim/issues/233)) ([649c5a9](https://github.com/shortcuts/no-neck-pain.nvim/commit/649c5a95236bd917d875caa8945fb36ec7bbad57))
* remove closed tab from state ([#235](https://github.com/shortcuts/no-neck-pain.nvim/issues/235)) ([8cca43d](https://github.com/shortcuts/no-neck-pain.nvim/commit/8cca43d7c6187f695eeccc48a7beacfbe95f8c00))
* tab state synchronization ([#231](https://github.com/shortcuts/no-neck-pain.nvim/issues/231)) ([137290b](https://github.com/shortcuts/no-neck-pain.nvim/commit/137290bccfad1a3f5bd0931dba3490991d1d3eeb))

## [1.2.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.2.1...v1.2.2) (2023-04-26)


### Bug Fixes

* refresh colorscheme ([#225](https://github.com/shortcuts/no-neck-pain.nvim/issues/225)) ([07e7c7e](https://github.com/shortcuts/no-neck-pain.nvim/commit/07e7c7e9f4fd4181bd9e0e2ac3379fe7b3a5ec0f))

## [1.2.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.2.0...v1.2.1) (2023-03-26)


### Bug Fixes

* register unfocused splits ([#218](https://github.com/shortcuts/no-neck-pain.nvim/issues/218)) ([3e766f9](https://github.com/shortcuts/no-neck-pain.nvim/commit/3e766f969361f998e204222e899d727df36e7816))
* split/vsplit state manager and fix weird resizes ([#215](https://github.com/shortcuts/no-neck-pain.nvim/issues/215)) ([0a81bc5](https://github.com/shortcuts/no-neck-pain.nvim/commit/0a81bc5ed883f8fec7ec934a8c8e28e9f5d0d14a))

## [1.2.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.1.1...v1.2.0) (2023-03-19)


### Features

* allow configuring scratchpad per side buffer ([#210](https://github.com/shortcuts/no-neck-pain.nvim/issues/210)) ([2a2b69e](https://github.com/shortcuts/no-neck-pain.nvim/commit/2a2b69edd4b64facb25535f6f2d9af0155b515a8))


### Bug Fixes

* leverage new Neotree commands ([#213](https://github.com/shortcuts/no-neck-pain.nvim/issues/213)) ([f620306](https://github.com/shortcuts/no-neck-pain.nvim/commit/f6203061cd1cfdc85df534e218ccbb27e21e3860))

## [1.1.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.1.0...v1.1.1) (2023-03-13)


### Bug Fixes

* side trees infinite polling ([#205](https://github.com/shortcuts/no-neck-pain.nvim/issues/205)) ([9af5a22](https://github.com/shortcuts/no-neck-pain.nvim/commit/9af5a22ba3e7be6ea5b11712c0c2d118f6807cb8))

## [1.1.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v1.0.0...v1.1.0) (2023-03-05)


### Features

* add toggle scratchPad mappings ([#203](https://github.com/shortcuts/no-neck-pain.nvim/issues/203)) ([475a34a](https://github.com/shortcuts/no-neck-pain.nvim/commit/475a34adf617d818c900e782cc7ccfd57ea9580f))

## [1.0.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.10.2...v1.0.0) (2023-03-04)


### ⚠ BREAKING CHANGES

* v1.0.0 - API breaking changes ([#201](https://github.com/shortcuts/no-neck-pain.nvim/issues/201))

If you were using the below options, make sure to move them to their new location when calling the `setup` method:

|   Before   |         After        |
|-------------|----------------------------|
|`enableOnVimEnter`|`autocmds.enableOnVimEnter`|
|`enableOnTabEnter`|`autocmds.enableOnTabEnter`|
|`toggleMapping`|`mappings.toggle`|
|`widthUpMapping`|`mappings.widthUp`|
|`widthDownMapping`|`mappings.widthDown`|
|`backgroundColor`|`colors.background`|
|`textColor`|`colors.text`|
|`blend`|`colors.blend`|
|`left.backgroundColor`|`left.colors.background`|
|`left.textColor`|`left.colors.text`|
|`left.blend`|`left.colors.blend`|
|`right.backgroundColor`|`right.colors.background`|
|`right.textColor`|`right.colors.text`|
|`right.blend`|`right.colors.blend`|

### Features

* v1.0.0 - API breaking changes ([#201](https://github.com/shortcuts/no-neck-pain.nvim/issues/201)) ([2b6cb3c](https://github.com/shortcuts/no-neck-pain.nvim/commit/2b6cb3c5e541b8cb58b6a1a593e7d7929b9eb61c))

## [0.10.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.10.1...v0.10.2) (2023-02-26)


### Bug Fixes

* vsplit wrongly sized ([#198](https://github.com/shortcuts/no-neck-pain.nvim/issues/198)) ([0d88b4a](https://github.com/shortcuts/no-neck-pain.nvim/commit/0d88b4a3fc89f80989cbf973797939dcb994f05c))

## [0.10.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.10.0...v0.10.1) (2023-02-23)


### Bug Fixes

* hide `colorcolumn` for side buffers by default ([#196](https://github.com/shortcuts/no-neck-pain.nvim/issues/196)) ([c101d4e](https://github.com/shortcuts/no-neck-pain.nvim/commit/c101d4e46f95516ce63fab104e87b631c3ed57b2))

## [0.10.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.9.3...v0.10.0) (2023-02-20)


### Features

* support neo-tree ([#192](https://github.com/shortcuts/no-neck-pain.nvim/issues/192)) ([755f466](https://github.com/shortcuts/no-neck-pain.nvim/commit/755f4663bf037331ce04d3c60cfc84f5ca26921d))

## [0.9.3](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.9.2...v0.9.3) (2023-02-15)


### Bug Fixes

* wrong focus when closing the main window ([#189](https://github.com/shortcuts/no-neck-pain.nvim/issues/189)) ([5067cfd](https://github.com/shortcuts/no-neck-pain.nvim/commit/5067cfdd0e3f33c659fa50c710785a2da70ca306))

## [0.9.2](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.9.1...v0.9.2) (2023-02-15)


### Bug Fixes

* prevent duplicate buffer name error with `setNames` ([#186](https://github.com/shortcuts/no-neck-pain.nvim/issues/186)) ([27b3167](https://github.com/shortcuts/no-neck-pain.nvim/commit/27b3167008e6c2ecdd6cf0dcf0100cf0e5241ad7))
* textColor blending ([#188](https://github.com/shortcuts/no-neck-pain.nvim/issues/188)) ([c2b8467](https://github.com/shortcuts/no-neck-pain.nvim/commit/c2b8467f9f51253a726c6232539280b4b486cd86))

## [0.9.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.9.0...v0.9.1) (2023-02-14)


### Bug Fixes

* events triggering multiple times ([#181](https://github.com/shortcuts/no-neck-pain.nvim/issues/181)) ([3890632](https://github.com/shortcuts/no-neck-pain.nvim/commit/389063273c96dd313cc15b471e18cd5b4be5e243))
* nil event check ([83e4990](https://github.com/shortcuts/no-neck-pain.nvim/commit/83e4990b9c5aa35863e8eaf4c55265c21f8c2750))
* transparent background with custom backgroundColor ([#185](https://github.com/shortcuts/no-neck-pain.nvim/issues/185)) ([6dde6dd](https://github.com/shortcuts/no-neck-pain.nvim/commit/6dde6dda0854e2facb7a841e17aa833287ac529d))

## [0.9.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.8.0...v0.9.0) (2023-02-11)


### Features

* add `minSidebufferWidth` ([#173](https://github.com/shortcuts/no-neck-pain.nvim/issues/173)) ([a64f5ec](https://github.com/shortcuts/no-neck-pain.nvim/commit/a64f5ecf2140b8932c52a9788dafc150a7b4ad9c))
* add up/down commands and mappings ([#168](https://github.com/shortcuts/no-neck-pain.nvim/issues/168)) ([4334618](https://github.com/shortcuts/no-neck-pain.nvim/commit/4334618121ac236c18b0d1fee95816e799108db2))
* support `blend` without background color ([#178](https://github.com/shortcuts/no-neck-pain.nvim/issues/178)) ([72c109e](https://github.com/shortcuts/no-neck-pain.nvim/commit/72c109eb164e695179f68b7d12ee1a66b72034fd))


### Bug Fixes

* `minSidebufferWidth` casing ([#177](https://github.com/shortcuts/no-neck-pain.nvim/issues/177)) ([edc68e5](https://github.com/shortcuts/no-neck-pain.nvim/commit/edc68e5cd721eed6bd9b0cd3073d24403a3c2fff))
* wrong side buffer width when toggling NvimTree ([#176](https://github.com/shortcuts/no-neck-pain.nvim/issues/176)) ([380df96](https://github.com/shortcuts/no-neck-pain.nvim/commit/380df965f452f3060fb0dcfce069a2eaf2257d4b))

## [0.8.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.7.0...v0.8.0) (2023-02-04)


### Features

* support `textwidth` and `colorcolumn` values for `width` ([#156](https://github.com/shortcuts/no-neck-pain.nvim/issues/156)) ([6456975](https://github.com/shortcuts/no-neck-pain.nvim/commit/6456975dab7b463f51feb274393eb00d0228ab63))
* **tabs:** provide an option to automatically enable the plugin ([#166](https://github.com/shortcuts/no-neck-pain.nvim/issues/166)) ([87fac46](https://github.com/shortcuts/no-neck-pain.nvim/commit/87fac462e29ea2eefc6edf0e06a60fc0cd51f9c4))

## [0.7.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.6.1...v0.7.0) (2023-02-02)


### Features

* add `NoNeckPainResize` command ([#162](https://github.com/shortcuts/no-neck-pain.nvim/issues/162)) ([3fc9c82](https://github.com/shortcuts/no-neck-pain.nvim/commit/3fc9c82add7e8cf4960d4140ea73ee2eb2c516b7))


### Bug Fixes

* transparent background support ([#164](https://github.com/shortcuts/no-neck-pain.nvim/issues/164)) ([f25795a](https://github.com/shortcuts/no-neck-pain.nvim/commit/f25795a31fc10642c63469f79a834c581895cce5))

## [0.6.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.6.0...v0.6.1) (2023-01-29)


### Bug Fixes

* split/vsplit computing ([#159](https://github.com/shortcuts/no-neck-pain.nvim/issues/159)) ([737c64f](https://github.com/shortcuts/no-neck-pain.nvim/commit/737c64f29ea5d5aa89cb17eab2a3d954066e737a))

## [0.6.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.5.0...v0.6.0) (2023-01-29)


### Features

* handle multiple tabs ([#154](https://github.com/shortcuts/no-neck-pain.nvim/issues/154)) ([3f0efca](https://github.com/shortcuts/no-neck-pain.nvim/commit/3f0efcab8b8b4d4eda91a238601879054bf30b43))
* keep side buffers on vsplit ([#145](https://github.com/shortcuts/no-neck-pain.nvim/issues/145)) ([0029fee](https://github.com/shortcuts/no-neck-pain.nvim/commit/0029fee8c840f495cbc887e95f5d8d6e07d735ad))
* keeps side buffers for current tab ([#150](https://github.com/shortcuts/no-neck-pain.nvim/issues/150)) ([e513dc3](https://github.com/shortcuts/no-neck-pain.nvim/commit/e513dc3e8f18e4cfe6ee1ebab6995110c7d57108))


### Bug Fixes

* cleanup after tab feature ([#158](https://github.com/shortcuts/no-neck-pain.nvim/issues/158)) ([5fe00a0](https://github.com/shortcuts/no-neck-pain.nvim/commit/5fe00a0e65197ff0c483b02fd3494eb2e93d1bfc))
* right color group never deleted ([#153](https://github.com/shortcuts/no-neck-pain.nvim/issues/153)) ([fce7bcb](https://github.com/shortcuts/no-neck-pain.nvim/commit/fce7bcbd82419d2b1b2e968385cdffa36c331484))

## [0.5.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.4.0...v0.5.0) (2023-01-15)


### Features

* add `onedark` theme ([#140](https://github.com/shortcuts/no-neck-pain.nvim/issues/140)) ([9bf7ca5](https://github.com/shortcuts/no-neck-pain.nvim/commit/9bf7ca58176108d959912e068bc04702bc1686de))
* add built-in scratchpad ([#141](https://github.com/shortcuts/no-neck-pain.nvim/issues/141)) ([d76812c](https://github.com/shortcuts/no-neck-pain.nvim/commit/d76812c2362c18c7b214fa8b4a6228c05dc3d834))
* properly position buffers with NvimTree ([#134](https://github.com/shortcuts/no-neck-pain.nvim/issues/134)) ([c1f5f2a](https://github.com/shortcuts/no-neck-pain.nvim/commit/c1f5f2ad26de5a5c0e08793fc195a70de171bbf4))


### Bug Fixes

* set scratchpad buffers as `unlisted` ([#143](https://github.com/shortcuts/no-neck-pain.nvim/issues/143)) ([5e215cf](https://github.com/shortcuts/no-neck-pain.nvim/commit/5e215cfcefa0dde4b6c7643c9bb44bac8bb59866))
* wrong size buffer width with NvimTree ([#144](https://github.com/shortcuts/no-neck-pain.nvim/issues/144)) ([cc388da](https://github.com/shortcuts/no-neck-pain.nvim/commit/cc388dac17abeca16a4a2184c839a741f28a6fef))

## [0.4.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.3.1...v0.4.0) (2023-01-12)


### Features

* add more default themes ([#130](https://github.com/shortcuts/no-neck-pain.nvim/issues/130)) ([58a39ff](https://github.com/shortcuts/no-neck-pain.nvim/commit/58a39ff29937dec7f33d816b94c1fb9b6229e434))
* default text color ([#131](https://github.com/shortcuts/no-neck-pain.nvim/issues/131)) ([6df43ae](https://github.com/shortcuts/no-neck-pain.nvim/commit/6df43aec515aa68d266172934f849d01a2a4b8fd))


### Bug Fixes

* prevent unwanted event trigger ([#135](https://github.com/shortcuts/no-neck-pain.nvim/issues/135)) ([60edd76](https://github.com/shortcuts/no-neck-pain.nvim/commit/60edd768df9df0d232de3c5142fb8fa6a333e02c))
* register command for nvim &lt;0.7 ([#138](https://github.com/shortcuts/no-neck-pain.nvim/issues/138)) ([b287cca](https://github.com/shortcuts/no-neck-pain.nvim/commit/b287cca9da5a6385f5d2c177c980563815383e39))

## [0.3.1](https://github.com/shortcuts/no-neck-pain.nvim/compare/v0.3.0...v0.3.1) (2023-01-06)


### Bug Fixes

* check if win is valid before using it ([#129](https://github.com/shortcuts/no-neck-pain.nvim/issues/129)) ([1b611f9](https://github.com/shortcuts/no-neck-pain.nvim/commit/1b611f9e7607faecd22cb3a1530419c0b0d9c2f3))
* weird layout when enabling the plugin with vsplit(s) opened ([#126](https://github.com/shortcuts/no-neck-pain.nvim/issues/126)) ([713f958](https://github.com/shortcuts/no-neck-pain.nvim/commit/713f958e4949cf2a9606e2c83cd3c143908fee1e))

## [0.3.0](https://github.com/shortcuts/no-neck-pain.nvim/compare/0.2.3...v0.3.0) (2023-01-05)


### Features

* add built-in nvim-tree and dashboard support ([#109](https://github.com/shortcuts/no-neck-pain.nvim/issues/109)) ([20ebf11](https://github.com/shortcuts/no-neck-pain.nvim/commit/20ebf111b5fb54ea23c98ed28af4cc4fa9f986b8))

## [0.2.3] - 2022-12-30
### Feat
- make side buffer a scratch pad ([#108](https://github.com/shortcuts/no-neck-pain.nvim/issues/108))
- add `enableOnVimEnter` option ([#107](https://github.com/shortcuts/no-neck-pain.nvim/issues/107))
- add `toggleMapping` option ([#105](https://github.com/shortcuts/no-neck-pain.nvim/issues/105))

### Fix
- prevent help split disabling nnp ([#106](https://github.com/shortcuts/no-neck-pain.nvim/issues/106))


<a name="0.2.2"></a>
## [0.2.2] - 2022-12-29
### Feat
- add release script ([#103](https://github.com/shortcuts/no-neck-pain.nvim/issues/103))
- add `blend` value to brighten/darken color background ([#74](https://github.com/shortcuts/no-neck-pain.nvim/issues/74))


<a name="0.2.1"></a>
## [0.2.1] - 2022-12-27
### Feat
- support undotree ([#100](https://github.com/shortcuts/no-neck-pain.nvim/issues/100))
- reduce number of resize event ([#98](https://github.com/shortcuts/no-neck-pain.nvim/issues/98))
- Allow custom Text Color ([#95](https://github.com/shortcuts/no-neck-pain.nvim/issues/95))

### Fix
- split/vsplit computing ([#96](https://github.com/shortcuts/no-neck-pain.nvim/issues/96))


<a name="0.2.0"></a>
## [0.2.0] - 2022-12-23
### Feat
- prevent split closing side buffers ([#92](https://github.com/shortcuts/no-neck-pain.nvim/issues/92))
- refactor setup ([#78](https://github.com/shortcuts/no-neck-pain.nvim/issues/78))
- handle side tree ([#79](https://github.com/shortcuts/no-neck-pain.nvim/issues/79))
- close side buffers when no space left ([#69](https://github.com/shortcuts/no-neck-pain.nvim/issues/69))
- **config:** cleanup fields and unused code ([#91](https://github.com/shortcuts/no-neck-pain.nvim/issues/91))

### Fix
- prevent `setup` wrong overrides ([#87](https://github.com/shortcuts/no-neck-pain.nvim/issues/87))
- adjust catppuccin colors to the correct values ([#85](https://github.com/shortcuts/no-neck-pain.nvim/issues/85))
- make setup-less easier ([#75](https://github.com/shortcuts/no-neck-pain.nvim/issues/75))

### BREAKING CHANGE

exposed configuration options have changed, make sure to check `:h NoNeckPain.options` or https://github.com/shortcuts/no-neck-pain.nvim#configuration if you have trouble configuring

exposed configuration options have changed, make sure to check `:h NoNeckPain.options` or https://github.com/shortcuts/no-neck-pain.nvim#configuration if you have trouble configuring


<a name="0.1.2"></a>
## [0.1.2] - 2022-12-18
### Feat
- add `rose-pine` color themes ([#58](https://github.com/shortcuts/no-neck-pain.nvim/issues/58))
- allow customizing bg color of side buffers ([#54](https://github.com/shortcuts/no-neck-pain.nvim/issues/54))
- support same buffer splits ([#52](https://github.com/shortcuts/no-neck-pain.nvim/issues/52))

### Fix
- quit Neovim when killing one of the last NNP buffer ([#66](https://github.com/shortcuts/no-neck-pain.nvim/issues/66))
- highlight group typo ([#65](https://github.com/shortcuts/no-neck-pain.nvim/issues/65))
- prevent config reset ([#63](https://github.com/shortcuts/no-neck-pain.nvim/issues/63))
- color leaving non-colored blocks ([#61](https://github.com/shortcuts/no-neck-pain.nvim/issues/61))
- prevent error on last buffer close ([#49](https://github.com/shortcuts/no-neck-pain.nvim/issues/49))


<a name="0.1.1"></a>
## [0.1.1] - 2022-12-15
### Docs
- generate documentation ([#31](https://github.com/shortcuts/no-neck-pain.nvim/issues/31))
- **README:** misspelled api ([#33](https://github.com/shortcuts/no-neck-pain.nvim/issues/33))

### Feat
- add `killAllBuffersOnDisable` option ([#41](https://github.com/shortcuts/no-neck-pain.nvim/issues/41))
- add `disableOnLastBuffer` option ([#37](https://github.com/shortcuts/no-neck-pain.nvim/issues/37))
- named side buffer ([#32](https://github.com/shortcuts/no-neck-pain.nvim/issues/32))

### Fix
- prevent force close window ([#47](https://github.com/shortcuts/no-neck-pain.nvim/issues/47))
- side buffers not closing when `killAllBuffersOnDisable` is false ([#44](https://github.com/shortcuts/no-neck-pain.nvim/issues/44))
- remove event redundancy ([#40](https://github.com/shortcuts/no-neck-pain.nvim/issues/40))


<a name="0.1.0"></a>
## [0.1.0] - 2022-12-11
### Feat
- **api:** make API extensible ([#27](https://github.com/shortcuts/no-neck-pain.nvim/issues/27))

### BREAKING CHANGE

exposed API and configuration have changed


<a name="0.0.1"></a>
## 0.0.1 - 2022-12-11
### Docs
- add wiki ([#25](https://github.com/shortcuts/no-neck-pain.nvim/issues/25))

### Feat
- disable NNP when killing side buffers ([#16](https://github.com/shortcuts/no-neck-pain.nvim/issues/16))
- left buffer only option ([#13](https://github.com/shortcuts/no-neck-pain.nvim/issues/13))
- add tests ([#4](https://github.com/shortcuts/no-neck-pain.nvim/issues/4))
- split screen support ([#3](https://github.com/shortcuts/no-neck-pain.nvim/issues/3))
- enable on WinEnter (closes [#1](https://github.com/shortcuts/no-neck-pain.nvim/issues/1))
- init no-neck-pain.nvim

### Fix
- NNP disabling not triggering ([#21](https://github.com/shortcuts/no-neck-pain.nvim/issues/21))
- condition for leftPaddingOnly
- prevent float window to kill side buffers ([#12](https://github.com/shortcuts/no-neck-pain.nvim/issues/12))
- unwanted `init` toggle ([#8](https://github.com/shortcuts/no-neck-pain.nvim/issues/8))
- prevent infinite config reset ([#7](https://github.com/shortcuts/no-neck-pain.nvim/issues/7))
- cleanup and more tests ([#6](https://github.com/shortcuts/no-neck-pain.nvim/issues/6))
- tests ([#5](https://github.com/shortcuts/no-neck-pain.nvim/issues/5))
- better split support
- remove `enableOnWinEnter`
- some padding wrongly toggling


[Unreleased]: https://github.com/shortcuts/no-neck-pain.nvim/compare/0.2.3...HEAD
[0.2.3]: https://github.com/shortcuts/no-neck-pain.nvim/compare/0.2.2...0.2.3
[0.2.2]: https://github.com/shortcuts/no-neck-pain.nvim/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/shortcuts/no-neck-pain.nvim/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/shortcuts/no-neck-pain.nvim/compare/0.1.2...0.2.0
[0.1.2]: https://github.com/shortcuts/no-neck-pain.nvim/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/shortcuts/no-neck-pain.nvim/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/shortcuts/no-neck-pain.nvim/compare/0.0.1...0.1.0
