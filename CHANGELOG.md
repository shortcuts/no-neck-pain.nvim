<a name="0.2.3"></a>
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
