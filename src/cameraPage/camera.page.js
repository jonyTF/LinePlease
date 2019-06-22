import React from 'react';
import { View, Text, Dimensions, TouchableOpacity, StatusBar } from 'react-native';
import { Camera } from 'expo-camera';
import * as Permissions from 'expo-permissions';
import { NavigationEvents } from 'react-navigation';
import * as ImagePicker from 'expo-image-picker';

import Toolbar from './toolbar.component';
import Gallery from './gallery.component';
import AcceptReject from './acceptReject.component';
import styles from '../styles';

const { width: winWidth, height: winHeight } = Dimensions.get('window');

// TODO: Make buttons more visible by adding a transparent (gray) background behind them
// TODO: After taking picture, add controls to straighten the image with a grid (by rotating)
//       and crop so it's only the text
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
    pendingPhotoData: null,
    hasCameraPermission: null,
    cameraOn: true,
  };

  setFlashMode = (flashMode) => this.setState({ flashMode });
  handleCaptureIn = () => this.setState({ capturing: true });

  pickImage = async () => {
    const image = await ImagePicker.launchImageLibraryAsync({ 
      mediaTypes: ImagePicker.MediaTypeOptions.Images, 
    });
    this.setState ({ captures: [image, ...this.state.captures] });
  };
  
  handleCaptureOut = async () => {
    this.setState({ capturing: false });
    const pendingPhotoData = await this.camera.takePictureAsync({ skipProcessing: true });
    this.setState({ pendingPhotoData });
    this.camera.pausePreview();
    //this.setState({ captures: [photoData, ...this.state.captures] });
  };

  handleSavePhotoData = () => {
    this.setState({ pendingPhotoData: null, captures: [this.state.pendingPhotoData, ...this.state.captures] });
    this.camera.resumePreview();
  };

  handleDiscardPhotoData = () => {
    this.setState({ pendingPhotoData: null });
    this.camera.resumePreview();
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
    const cameraRoll = await Permissions.askAsync(Permissions.CAMERA_ROLL);
    const hasCameraPermission = (camera.status === 'granted' && cameraRoll.status === 'granted');

    this.setState({ hasCameraPermission });

    await this.setRatio();
  };

  render() {
    const { hasCameraPermission, flashMode, cameraType, capturing, captures, ratio, cameraWidth, cameraHeight, pendingPhotoData, cameraOn } = this.state;

    if (hasCameraPermission === null) {
      return <View />;
    } else if (hasCameraPermission === false) {
      return <Text>Access to camera was denied.</Text>;
    }

    return (
      <React.Fragment>
        <StatusBar hidden />

        <NavigationEvents 
          onWillFocus={() => this.setState({ cameraOn: true })}
          onDidBlur={() => this.setState({ cameraOn: false })}
        />
        
        
        <View>
          { cameraOn &&
            <Camera
              type={cameraType}
              ratio={ratio}
              flashMode={flashMode}
              style={[styles.preview, {width: cameraWidth, height: cameraHeight}]}
              ref={camera => this.camera = camera}
            />
          }
        </View>
        
        {pendingPhotoData ? 
          <AcceptReject 
            savePhotoData={this.handleSavePhotoData}
            discardPhotoData={this.handleDiscardPhotoData}
          />
          :
          <React.Fragment>
            <TouchableOpacity style={styles.leftTopBtn} onPress={null}>
              <Text style={styles.btnText}>Cancel</Text>
            </TouchableOpacity>
            
            <TouchableOpacity style={styles.rightTopBtn} onPress={() => this.props.navigation.navigate('Upload', { captures })}>
              <Text style={styles.btnText}>Done</Text>
            </TouchableOpacity>

            {captures.length > 0 && <Gallery captures={captures} />}

            <Toolbar 
              capturing={capturing}
              flashMode={flashMode}
              cameraType={cameraType}
              setFlashMode={this.setFlashMode}
              pickImage={this.pickImage}
              onCaptureIn={this.handleCaptureIn}
              onCaptureOut={this.handleCaptureOut}
            />
          </React.Fragment>
        }
      </React.Fragment>
    );
  };
};