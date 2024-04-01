First beta version of paper sricker camera. 

How it works:
- `StickerProcessor` is responsible to all Core processes 
- Vision is resposible for segmentation (`SegmentationService`)
- Sticker creation is build with Metal kernels (`AlphaMaskKernel`, `PaperMaskKernel`, `StickerKernel`, `Brush`)

What to imrove:
- Support Landscape orientation
- Cache intermediate textures for switch paper
- Handle errors from `CaptureService` and `StickerProcessor`
- Clear textures in `OffscreenRenderer` if necessary
- Move `Core` to local Swift Package
- Move `CameraModule` to local Swift Package
- Add XcodeGen
