import React from 'react';
import { Text, View, Image, Dimensions, StatusBar, Button, TouchableOpacity } from 'react-native';
import * as ImageManipulator from 'expo-image-manipulator';
import Config from 'react-native-config';
import * as FileSystem from 'expo-file-system';
import { ScreenOrientation } from 'expo';
import { LinearGradient } from 'expo-linear-gradient';

import styles from '../styles';
import data from './testdata';

const { width: winWidth, height: winHeight } = Dimensions.get('window');

// TODO: Add zooming and horizontal panning

export default class UploadPage extends React.Component {
  state = {
    croppedLines: [],
    curLine: 0,
    curCharacters: ['FJ:', 'F):', 'F]:'],
    linesByCharacter: {},
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

  addToCharacterLines = (curName, curWords) => {
    console.log(curName);
    if (curName in this.state.linesByCharacter) {
      this.state.linesByCharacter[curName] = this.state.linesByCharacter[curName].concat(curWords);
    } else { 
      this.state.linesByCharacter[curName] = curWords;
    }
  };

  normalizeWordCoords = (words, screenFactor) => {
    // Normalizes ocr space coords to window coords
    for (let i = 0; i < words.length; i++) {
      words[i].Height *= screenFactor;
      words[i].Width *= screenFactor;
      words[i].Left *= screenFactor;
      words[i].Top *= screenFactor;
    }
  };

  isName = (text) => {
    return text.length >= 2 && text === text.toUpperCase();
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

    let curName = '';
    let curWords = [];
    for (let line of textOverlay.Lines) {
      const firstWord = line.Words[0].WordText;
      if (this.isName(firstWord)) {
        // If the current line has a name in it
        if (curName.length > 0) {
          this.normalizeWordCoords(curWords, screenFactor);
          this.addToCharacterLines(curName, curWords);
          curName = '';
          curWords = [];
        }

        bot = line.MinTop * screenFactor;
        cropY.push({top, bot});
        top = bot;

        curName = firstWord;

        let i;
        for (i = 1; i < line.Words.length; i++) {
          if (this.isName(line.Words[i].WordText))
            curName += ' ' + line.Words[i].WordText;
          else
            break;
        }

        curWords = curWords.concat(line.Words.slice(i));
      } else {
        curWords = curWords.concat(line.Words);
      }
    }
    this.normalizeWordCoords(curWords, screenFactor);
    this.addToCharacterLines(curName, curWords);
    
    cropY.push({top, bot: imHeight*screenFactor});

    this.setState({ 
      croppedLines: [...this.state.croppedLines, cropY]
    });
  }

  nextLine = () => {
    const { croppedLines, curLine } = this.state;
    const curCropList = croppedLines[0];
    if (curLine + 1 < curCropList.length) 
      this.setState({ curLine: curLine + 1 });
  };

  prevLine = () => {
    const { curLine } = this.state;
    if (curLine - 1 >= 0) 
      this.setState({ curLine: curLine - 1 });
  };

  render() {
    const captures = this.props.navigation.getParam('captures', []);
    const { croppedLines, curLine, curCharacters, linesByCharacter } = this.state;
    const curCropList = croppedLines[0];

    return (
      <React.Fragment>
        <StatusBar hidden={true} />
        <View>
          { croppedLines.length > 0 && 
          <View>
            <Image 
              source={{uri: captures[0].uri}}
              style={ 
                    {  width: winHeight, 
                        height: captures[0].height * winHeight/captures[0].width,
                        position: 'absolute',  
                        top: winWidth/2 - (curCropList[curLine].bot-curCropList[curLine].top)/2 - curCropList[curLine].top,
                    }}
            />
            <LinearGradient
              colors={['rgba(0, 0, 0, 0.9)', 'rgba(0, 0, 0, 0.5)']}
              style={{
                position: 'absolute',
                left: 0,
                top: 0,
                width: winHeight,
                height: (winWidth - (curCropList[curLine].bot-curCropList[curLine].top)) / 2,
              }}
            >
              <TouchableOpacity onPress={this.prevLine} style={{flex: 1}} />
            </LinearGradient>
            <LinearGradient
              colors={['rgba(0, 0, 0, 0.5)', 'rgba(0, 0, 0, 0.9)']}
              style={{
                position: 'absolute',
                left: 0,
                top: (winWidth - (curCropList[curLine].bot-curCropList[curLine].top)) / 2 + (curCropList[curLine].bot-curCropList[curLine].top),
                width: winHeight,
                height: (winWidth - (curCropList[curLine].bot-curCropList[curLine].top)) / 2,
              }}
            >
              <TouchableOpacity onPress={this.nextLine} style={{flex: 1}} />
            </LinearGradient>

            { // TODO: make this depend on curLine
              curCharacters.map((name, i) => {
                if (name in linesByCharacter) {
                  return linesByCharacter[name].map((wordBox, j) => (
                    <View 
                      key={i + '_' + j}
                      style={{
                        backgroundColor: 'black',
                        position: 'absolute',
                        width: wordBox.Width,
                        height: wordBox.Height,
                        top: winWidth/2 - (curCropList[curLine].bot-curCropList[curLine].top)/2 - curCropList[curLine].top + wordBox.Top,
                        left: wordBox.Left
                      }}
                    />
                  ));
                }
                return null;
              })
              
            }
            <View 
              style={{
                backgroundColor: 'black',
                position: 'absolute',
                width: 20,
                height: 20,
                top: 10,
                left: 10
              }}
            />
          </View>
          }
        </View>
      </React.Fragment>
    );
  };
}