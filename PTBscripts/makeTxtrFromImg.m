function [TextureIndex imgsize] = makeTxtrFromImg(imgfile, imgtype, PTBParams)  
    ImageInfo = imread(imgfile, imgtype);
    imgsize = size(ImageInfo);
    TextureIndex = Screen('MakeTexture',PTBParams.win,ImageInfo);