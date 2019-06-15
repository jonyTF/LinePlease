import React from 'react';
import { createStackNavigator, createAppContainer } from 'react-navigation';
import CameraPage from './src/cameraPage/camera.page';
import UploadPage from './src/uploadPage/upload.page';

const AppNavigator = createStackNavigator(
  {
    Camera: {
      screen: CameraPage,
      navigationOptions: {
        header: null
      },
    },
    Upload: UploadPage,
  },
  {
    initialRouteName: 'Camera',
  },
);

const AppContainer = createAppContainer(AppNavigator);

export default class App extends React.Component {
  render() {
    return <AppContainer />;
  }
}