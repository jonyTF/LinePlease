import React from 'react';
import { View, Image, TouchableOpacity, TouchableNativeFeedback, Dimensions, StatusBar, Platform } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { ScreenOrientation } from 'expo';

const { width: winWidth, height: winHeight } = Dimensions.get('window');

export default class ShowLinesPage extends React.Component {
  state = {
    curLine: 0,
    curCharacters: ['FJ:', 'F):', 'F]:'],
    linesByCharacter: {},
    croppedLines: [],
  };

  componentDidMount() {
    ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.LANDSCAPE_LEFT);
    this.cropLines(this.props.navigation.getParam('capture', []), this.props.navigation.getParam('ocrData', []));
  };

  addToCharacterLines = (curName, curWords, screenFactor) => {
    let rects = [];
    for (let line of curWords) {
      let minTop = line[0].Top;
      let minLeft = line[0].Left;
      let maxLeftWidth = line[0].Left + line[0].Width;
      let maxTopHeight = line[0].Top + line[0].Height;
      for (let i = 1; i < line.length; i++) {
        if (line[i].Top < minTop) {
          minTop = line[i].Top;
        }
        if (line[i].Left < minLeft) {
          minLeft = line[i].Left;
        }
        if (line[i].Left + line[i].Width > maxLeftWidth) {
          maxLeftWidth = line[i].Left + line[i].Width;
        }
        if (line[i].Top + line[i].Height > maxTopHeight) {
          maxTopHeight = line[i].Top + line[i].Height
        }
      }

      // Normalizes ocr space coords to window coords
      minTop *= screenFactor;
      minLeft *= screenFactor;
      maxLeftWidth *= screenFactor;
      maxTopHeight *= screenFactor;

      let rect = {
        top: minTop,
        left: minLeft,
        width: maxLeftWidth - minLeft,
        height: maxTopHeight - minTop,
      };
      rects.push(rect);
    }

    console.log(curName);
    if (curName in this.state.linesByCharacter) {
      this.state.linesByCharacter[curName] = this.state.linesByCharacter[curName].concat(rects);
    } else { 
      this.state.linesByCharacter[curName] = rects;
    }
  };

  isName = (text) => {
    return text.length >= 2 && text === text.toUpperCase();
  };

  cropLines = async (capture, ocrData) => {
    console.log('GET OCR DATA');
    //const ocrData = await this.getImageText(capture);

    console.log('CROPPED LINES START');
    console.log(ocrData);
    const textOverlay = ocrData.overlay;
    const orientation = parseInt(ocrData.orientation);
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
          if (curWords.length > 0)
            this.addToCharacterLines(curName, curWords, screenFactor);
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

        let words = line.Words.slice(i);
        if (words.length > 0)
          curWords.push(words);
      } else {
        let words = line.Words;
        if (words.length > 0)
          curWords.push(words);
      }
    }
    this.addToCharacterLines(curName, curWords, screenFactor);
    
    cropY.push({top, bot: imHeight*screenFactor});

    this.setState({ 
      croppedLines: cropY
    });
  }

  nextLine = () => {
    const { croppedLines, curLine } = this.state;
    if (curLine + 1 < croppedLines.length) 
      this.setState({ curLine: curLine + 1 });
  };

  prevLine = () => {
    const { curLine } = this.state;
    if (curLine - 1 >= 0) 
      this.setState({ curLine: curLine - 1 });
  };

  render() {
    const TouchablePlatformSpecific = Platform.OS === 'ios' ? 
        TouchableOpacity : 
        TouchableNativeFeedback;

    const capture = this.props.navigation.getParam('capture', []);
    const { croppedLines, curLine, curCharacters, linesByCharacter } = this.state;


    return (
      <React.Fragment>
        <StatusBar hidden={true} />
        { croppedLines.length > 0 && 
          <View>
            <Image 
              source={{uri: capture.uri}}
              style={ 
                    {  width: winHeight, 
                        height: capture.height * winHeight/capture.width,
                        position: 'absolute',  
                        top: winWidth/2 - (croppedLines[curLine].bot-croppedLines[curLine].top)/2 - croppedLines[curLine].top,
                    }}
            />
            <LinearGradient
              colors={['rgba(0, 0, 0, 0.9)', 'rgba(0, 0, 0, 0.5)']}
              style={{
                position: 'absolute',
                left: 0,
                top: 0,
                width: winHeight,
                height: (winWidth - (croppedLines[curLine].bot-croppedLines[curLine].top)) / 2,
              }}
            >
              <TouchablePlatformSpecific onPress={this.prevLine} style={{flex: 1}} />
            </LinearGradient>
            <LinearGradient
              colors={['rgba(0, 0, 0, 0.5)', 'rgba(0, 0, 0, 0.9)']}
              style={{
                position: 'absolute',
                left: 0,
                top: (winWidth - (croppedLines[curLine].bot-croppedLines[curLine].top)) / 2 + (croppedLines[curLine].bot-croppedLines[curLine].top),
                width: winHeight,
                height: (winWidth - (croppedLines[curLine].bot-croppedLines[curLine].top)) / 2,
              }}
            >
              <TouchablePlatformSpecific onPress={this.nextLine} style={{flex: 1}} />
            </LinearGradient>

            {
              curCharacters.map((name, i) => {
                if (name in linesByCharacter) {
                  return linesByCharacter[name].map((rect, j) => (
                    <View 
                      key={i + '_' + j}
                      style={{
                        backgroundColor: 'black',
                        position: 'absolute',
                        width: rect.width,
                        height: rect.height,
                        top: winWidth/2 - (croppedLines[curLine].bot-croppedLines[curLine].top)/2 - croppedLines[curLine].top + rect.top,
                        left: rect.left
                      }}
                    />
                  ));
                }
                return null;
              })
              
            }
          </View>
        }
      </React.Fragment>
    );
  };
}