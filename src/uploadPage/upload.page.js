import React from 'react';
import { StatusBar, TextInput } from 'react-native';
import * as ImageManipulator from 'expo-image-manipulator';
import Config from 'react-native-config';
import * as FileSystem from 'expo-file-system';
import { ScreenOrientation } from 'expo';
import { NavigationEvents } from 'react-navigation';
import { Divider } from 'react-native-elements';

import Gallery from './gallery.component';

import styles from '../styles';
import data from './testdata';

// TODO: Add zooming and horizontal panning
// TODO: Add selection box that allows you to choose which character to black lines out for

export default class UploadPage extends React.Component {
  state = {
    ocrDataList: [],
    captures: [],
    title: 'New Script',
  };

  componentDidMount() {
    ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.PORTRAIT_UP);
    const captures = this.props.navigation.getParam('captures', []);
    if (captures.length > 0)
      this.getOCRData();
  };

  resizeImage = async (capture) => {
    // Resize image so it's under the file size limit for OCR.space
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
    // Use the OCR.space API to get the image text
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

  getOCRData = async () => {
    const captures = this.props.navigation.getParam('captures', []);
    for (let capture of captures) {
      //const ocrData = await this.getImageText(capture);
      const ocrData = {overlay: data, orientation: 0};
      this.setState({ ocrDataList: [...this.state.ocrDataList, ocrData]});
    }
  };

  showLines = (index) => {
    const { ocrDataList } = this.state;
    const captures = this.props.navigation.getParam('captures', []);
    this.props.navigation.navigate('ShowLines', { capture: captures[index], ocrData: ocrDataList[index] });
  };

  render() {
    const { ocrDataList, title } = this.state;
    const captures = this.props.navigation.getParam('captures', []);

    return (
      <React.Fragment>
        <StatusBar hidden={false} />
        <NavigationEvents 
          onWillFocus={() => ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.PORTRAIT_UP)}
          onDidBlur={null}
        />
        
        <TextInput 
          onChangeText={text => this.setState({ title: text })}
          value={title}
          multiline={true}
          style={{
            borderBottomColor: 'black',
            borderBottomWidth: 2,
            alignSelf: 'center',
            fontSize: 50,
            marginTop: 10,
            marginBottom: 10,
            marginLeft: 10,
            marginRight: 10,
          }}
        />
        { false &&
        <Divider 
          style={{
            marginBottom: 20,
            height: 1,
            marginRight: 10,
            marginLeft: 10,
          }}
        />
        }

        <Gallery captures={captures} ocrDataList={ocrDataList} showLines={this.showLines} />
      </React.Fragment>
    );
  };
}