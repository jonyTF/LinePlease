import React from 'react';
import { View, Text, Dimensions } from 'react-native';
import { Camera } from 'expo-camera';
import * as Permissions from 'expo-permissions';

import Toolbar from './toolbar.component';
import Gallery from './gallery.component';
import styles from './styles';

const { width: winWidth, height: winHeight } = Dimensions.get('window');

export default class CameraPage extends React.Component {
  camera = null;
  state = {
    captures: [],
    flashMode: Camera.Constants.FlashMode.off,
    capturing: null,
    cameraType: Camera.Constants.Type.back,
    ratio: '4:3',
    cameraWidth: winWidth,
    cameraHeight: winHeight,
    hasCameraPermission: null,
  };

  setFlashMode = (flashMode) => this.setState({ flashMode });
  setCameraType = (cameraType) => this.setState({ cameraType });
  handleCaptureIn = () => this.setState({ capturing: true });

  handleCaptureOut = () => {
    if (this.state.capturing)
      this.camera.stopRecording();
  };

  handleShortCapture = async () => {
    const photoData = await this.camera.takePictureAsync();
    this.setState({ capturing: false, captures: [photoData, ...this.state.captures] });
  };

  handleLongCapture = async () => {
    const videoData = await this.camera.recordAsync();
    this.setState({ capturing: false, captures: [videoData, ...this.state.captures] });
  };

  setRatio = async () => {
    const supportedRatios = await this.camera.getSupportedRatiosAsync();
    const screenRatioDecimal = winHeight / winWidth;

    let leastDiff = 99;
    let leastRatio = '';
    let leastRatioDecimal = 0;
    for (let ratio of supportedRatios) {
      const [w, h] = ratio.split(':');
      const ratioDecimal = parseInt(w) / parseInt(h);
      const diff = Math.abs(screenRatioDecimal - ratioDecimal);
      if (diff < leastDiff) {
        leastDiff = diff;
        leastRatio = ratio;
        leastRatioDecimal = ratioDecimal;
      }
    }

    let cameraHeight = winHeight;
    let cameraWidth = winHeight*(1/leastRatioDecimal);
    if (cameraWidth < winWidth) {
      cameraHeight = winWidth*leastRatioDecimal;
      cameraWidth = winWidth;
    }

    this.setState({ ratio: leastRatio, cameraWidth, cameraHeight });
  };

  async componentDidMount() {
    const camera = await Permissions.askAsync(Permissions.CAMERA);
    const audio = await Permissions.askAsync(Permissions.AUDIO_RECORDING);
    const hasCameraPermission = (camera.status === 'granted' && audio.status === 'granted');

    this.setState({ hasCameraPermission });

    await this.setRatio();
  };

  render() {
    const { hasCameraPermission, flashMode, cameraType, capturing, captures, ratio, cameraWidth, cameraHeight } = this.state;

    if (hasCameraPermission === null) {
      return <View />;
    } else if (hasCameraPermission === false) {
      return <Text>Access to camera was denied.</Text>
    }

    return (
      <React.Fragment>
        <View>
          <Camera
            type={cameraType}
            ratio={ratio}
            flashMode={flashMode}
            style={[styles.preview, {width: cameraWidth, height: cameraHeight}]}
            ref={camera => this.camera = camera}
          />
        </View>

        {captures.length > 0 && <Gallery captures={captures} />}

        <Toolbar 
          capturing={capturing}
          flashMode={flashMode}
          cameraType={cameraType}
          setFlashMode={this.setFlashMode}
          setCameraType={this.setCameraType}
          onCaptureIn={this.handleCaptureIn}
          onCaptureOut={this.handleCaptureOut}
          onShortCapture={this.handleShortCapture}
          onLongCapture={this.handleLongCapture}
        />
      </React.Fragment>
    );
  };
};