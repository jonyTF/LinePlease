import React from 'react';
import { Text, View, Image, Dimensions, StatusBar, Button } from 'react-native';
import * as ImageManipulator from 'expo-image-manipulator';
import Config from 'react-native-config';
import * as FileSystem from 'expo-file-system';
import { ScreenOrientation } from 'expo';

import styles from '../styles';
import data from './testdata';

const { width: winWidth, height: winHeight } = Dimensions.get('window');

export default class UploadPage extends React.Component {
  state = {
    croppedLines: [],
    curLine: 0,
  };

  componentDidMount() {
    ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.LANDSCAPE_LEFT);
    const captures = this.props.navigation.getParam('captures', []);
    if (captures.length > 0)
      this.cropLines(captures[0]);
  };

  resizeImage = async (capture) => {
    let compressIndex = 0;
    const compressValues = [{compress: 1, width: 0}, 
                            {compress: 0.9, width: 0},
                            {compress: 0.8, width: 0},
                            {compress: 0.7, width: 0},
                            {compress: 0.6, width: 0},
                            {compress: 1, width: 1000},
                            {compress: 0.9, width: 1000},
                            {compress: 0.8, width: 1000},
                            {compress: 0.7, width: 1000},
                            {compress: 0.6, width: 1000},
                            {compress: 0.5, width: 1000},
                            {compress: 0.4, width: 1000},
                            {compress: 0.3, width: 1000},
                            {compress: 0.2, width: 1000},
                            {compress: 0.1, width: 1000},
                            {compress: 0, width: 1000},
                          ];
    const fileSizeLimit = 1024;
    let manipResult;
    while (true) {
      const width = compressValues[compressIndex].width;
      const compress = compressValues[compressIndex].compress;
      manipResult = await ImageManipulator.manipulateAsync(
        capture.uri,
        width == 0 ? [] : [ { resize: { width: width } } ],
        { 
          base64: true, 
          compress: compress,
        }
      );
      const info = await FileSystem.getInfoAsync(manipResult.uri, { size: true });
      console.log('Image size: ', info.size);
      if (info.size / 1000 < fileSizeLimit || compressIndex + 1 == compressValues.length) {
        break;
      } else {
        compressIndex += 1;
      }
    }
    console.log('compression: ', compressValues[compressIndex]);
    return manipResult.base64;
  };

  getImageText = async (capture) => {
    const base64Image = await this.resizeImage(capture);

    let formData = new FormData();
    formData.append('base64Image', 'data:image/jpg;base64,' + base64Image);
    formData.append('scale', true);
    formData.append('isOverlayRequired', true);
    formData.append('detectOrientation', true);

    const textOverlay = await fetch('https://api.ocr.space/parse/image', {
      method: 'POST',
      headers: {
        apikey: '',
        'Content-Type': 'multipart/form-data'
      },
      body: formData,
    })
      .then(response => response.json())
      .then(responseJson => {
        if ('ParsedResults' in responseJson) {
          console.log('Yes parsed results');
          return {overlay: responseJson.ParsedResults[0].TextOverlay, orientation: responseJson.ParsedResults[0].TextOrientation};
        }
        return { error: 'Error getting OCR text. Please try again later.' };
      })
      .catch(error => {
        return { error };
      });

    return textOverlay;
  };

  cropLines = async (capture) => {
    console.log('GET OCR DATA');
    //const ocrData = await this.getImageText(capture);

    console.log('CROPPED LINES START');
    //const textOverlay = ocrData.overlay;
    //const orientation = parseInt(ocrData.orientation);
    const textOverlay = data;
    const orientation = 0;
    console.log(textOverlay);
    
    if ('error' in textOverlay) {
      console.log('ERROR');
      console.log(textOverlay.error);
      return;
    }
    // TODO(URGENT): handle the possible error from textOverlay
    //                Also: what if textOverlay is empty??

    // TODO: Adjust code so it adapts to whether the size of image has been manipulated to be under 1 kb
    //       Do this either by cropping the original image, or by multiplying the textOverlay values by a factor

    let cropY = [];
    let top = 0;
    let bot = 0;
    const isSideways = orientation == 270 || orientation == 90;
    const imWidth = isSideways ? capture.height : capture.width;
    const imHeight = isSideways ? capture.width : capture.height;

    const screenFactor = winHeight/imWidth;

    for (let line of textOverlay.Lines) {
      const firstWord = line.Words[0].WordText;
      if (firstWord.length >= 2 && firstWord === firstWord.toUpperCase()) {
        bot = line.MinTop * screenFactor;
        cropY.push({top, bot});
        top = bot;
      }
    }
    cropY.push({top, bot: imHeight*screenFactor});
    console.log('crop list done');

    console.log(cropY);
    console.log(capture.height);
    // TODO: convert cropY to screen coordinates

    /*
    let croppedImages = [];
    for (let crop of cropY) {
      const croppedImage = await ImageManipulator.manipulateAsync(
        capture.uri,
        [{ rotate: orientation },
        { crop: { originX: 0, originY: crop.top, width: imWidth, height: crop.bot - crop.top } }]
      );
      croppedImages.push(croppedImage);
    }

    this.setState({ croppedLines: 
      [...this.state.croppedLines, {
        origImage: capture,
        croppedImages
      }]
    });
    */
    this.setState({ 
      croppedLines: [...this.state.croppedLines, cropY]
    });

    console.log('CROPPED LINES DONE');
    //console.log(this.state.croppedLines);
  }

  render() {
    const captures = this.props.navigation.getParam('captures', []);
    const { croppedLines, curLine } = this.state;
    const curCropList = croppedLines[0];

    return (
      <React.Fragment>
        <StatusBar hidden={true} />
        <View>
          {/*
            croppedLines.map((curPage) => {
              return curPage.croppedImages.map((image) => {
                console.log(image);
                return (
                  <Image 
                    key={image.uri}
                    source={{ uri: image.uri }}
                    style={{ width: winHeight, height: image.height * winHeight/image.width, marginBottom: 15}}
                  />
                );
              })
            })*/
          }

          {
            /*croppedLines.length > 0 && 
            <Image 
              source={{uri: croppedLines[0].croppedImages[0].uri}}
              style={{ width: 1000, height: 300}}
            />
            */
          }

          { croppedLines.length > 0 &&
          <Image 
            source={{uri: captures[0].uri}}
            style={ // TODO: use `top` w/ negative numbers to center the correct line  
                  {  width: winHeight, 
                      height: captures[0].height * winHeight/captures[0].width,
                      position: 'absolute',  
                      top: winWidth/2 - (curCropList[curLine].bot-curCropList[curLine].top)/2 - curCropList[curLine].top,
                  }}
          />
          }

          <Button title="TEST" onPress={() => {if (curLine + 1 < curCropList.length) this.setState({ curLine: curLine + 1 })}} style={{position: 'absolute', top: 10, right: 10}}/>
        </View>
      </React.Fragment>
    );
  };
}