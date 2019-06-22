import React from 'react';
import { View, StatusBar } from 'react-native';
import { Button } from 'react-native-elements';
import * as ImagePicker from 'expo-image-picker';
import * as Permissions from 'expo-permissions';
import { ScreenOrientation } from 'expo';
import { NavigationEvents } from 'react-navigation';

import styles from '../styles';

// TODO: CHECK if need to do permission stuff
export default class InputScriptPage extends React.Component {
  componentDidMount() {
    ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.PORTRAIT_UP);
  };

  takePictures = async () => {
    const image = await ImagePicker.launchCameraAsync();
    this.props.navigation.navigate('Upload', { captures: [image] });
  };
  
  importPictures = async () => {
    const image = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true
    });
    console.log(image);
    this.props.navigation.navigate('Upload', { captures: [image] });
  };

  // Perhaps replace the button text with image buttons
  render() {
    return (
      <View style={styles.alignCenter}>
        <StatusBar hidden={false} />
        <NavigationEvents 
          onWillFocus={() => ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.PORTRAIT_UP)}
          onDidBlur={null}
        />

        <Button
          title="Take pictures of script"
          style={styles.btn}
        />
        <Button 
          title="Import pictures of script"
          style={styles.btn}
          onPress={this.importPictures}
        />
        <Button 
          title="Import existing script from community"
          style={styles.btn}
        />
      </View>
    );
  }
}