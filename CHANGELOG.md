<a name="0.2.3"></a>
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
