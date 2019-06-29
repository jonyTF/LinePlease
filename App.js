import React from 'react';
import { createStackNavigator, createAppContainer } from 'react-navigation';
import CameraPage from './src/cameraPage/camera.page';
import UploadPage from './src/uploadPage/upload.page';
import InputScriptPage from './src/inputScriptPage/inputScript.page';
import ShowLinesPage from './src/showLinesPage/showLines.page';

const AppNavigator = createStackNavigator(
  {
    Camera: {
      screen: CameraPage,
      navigationOptions: {
        header: null
      },
    },
    Upload: {
      screen: UploadPage,
    },
    InputScript: InputScriptPage,
    ShowLines: {
      screen: ShowLinesPage,
      navigationOptions: {
        header: null,
      },
    }
  },
  {
    initialRouteName: 'ShowLines',
  },
);

const AppContainer = createAppContainer(AppNavigator);

export default class App extends React.Component {
  render() {
    return <AppContainer />;
  }
}