import React from 'react';
import { Dimensions, StatusBar, Animated } from 'react-native';
import { ScreenOrientation } from 'expo';

import Main from './main.component';
import data from '../uploadPage/testdata';

const { width: winWidth, height: winHeight } = Dimensions.get('window');


export default class ShowLinesPage extends React.Component {
  state = {
    curLine: 0,
    curCharacters: ['FJ:', 'F):', 'F]:'],
    linesByCharacter: {},
    croppedLines: [],
    cropTop: new Animated.Value(0),
    cropBot: new Animated.Value(0),
  };

  componentDidMount() {
    ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.LANDSCAPE_LEFT);
    //const capture = this.props.navigation.getParam('capture', []);
    const capture = {
      "cancelled": false,
      "height": 4048,
      "type": "image",
      "uri": "file:///data/user/0/host.exp.exponent/cache/ExperienceData/%2540anonymous%252FLinePlease-94cdde7e-05b2-4193-bef6-6fa95eedda87/ImagePicker/495c495c-9e24-4645-bcaa-535975d96dcb.jpg",
      "width": 3036,
    };
    //const ocrData = this.props.navigation.getParam('ocrData', []);
    const ocrData = {overlay: data, orientation: 0};
    this.cropLines(capture, ocrData);
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
    console.log(capture);
    console.log('GET OCR DATA');
    //const ocrData = await this.getImageText(capture);

    console.log('CROPPED LINES START');
    const textOverlay = ocrData.overlay;
    const orientation = parseInt(ocrData.orientation);
    //console.log(textOverlay);
    
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

    this.state.cropTop.setValue(cropY[0].top);
    this.state.cropBot.setValue(cropY[0].bot);

    this.setState({ 
      croppedLines: cropY
    });
  }

  animateToLine = (lineNum) => {
    Animated.parallel([
      Animated.spring(
        this.state.cropTop,
        {
          toValue: this.state.croppedLines[lineNum].top,
        }
      ),
      Animated.spring(
        this.state.cropBot,
        {
          toValue: this.state.croppedLines[lineNum].bot,
        }
      )
    ]).start();
  }

  nextLine = () => {
    const { croppedLines, curLine } = this.state;
    if (curLine + 1 < croppedLines.length) {
      this.setState({ curLine: curLine + 1 });
      this.animateToLine(curLine + 1);
    }
  };

  prevLine = () => {
    const { curLine } = this.state;
    if (curLine - 1 >= 0) {
      this.setState({ curLine: curLine - 1 });
      this.animateToLine(curLine - 1);
    }
  };

  render() {
    //const capture = this.props.navigation.getParam('capture', []);
    const capture = {
      "cancelled": false,
      "height": 4048,
      "type": "image",
      "uri": "file:///data/user/0/host.exp.exponent/cache/ExperienceData/%2540anonymous%252FLinePlease-94cdde7e-05b2-4193-bef6-6fa95eedda87/ImagePicker/495c495c-9e24-4645-bcaa-535975d96dcb.jpg",
      "width": 3036,
    }; 
    const { croppedLines, curLine, curCharacters, linesByCharacter, cropTop, cropBot } = this.state;

    return (
      <React.Fragment>
        <StatusBar hidden={true} />
        { croppedLines.length > 0 && 
          <Main 
            capture={capture}
            curCharacters={curCharacters}
            linesByCharacter={linesByCharacter}
            cropTop={cropTop}
            cropBot={cropBot}
            nextLine={this.nextLine}
            prevLine={this.prevLine}
          />
        }
      </React.Fragment>
    );
  };
}