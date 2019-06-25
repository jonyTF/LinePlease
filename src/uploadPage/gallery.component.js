import React from 'react';
import { View, ImageBackground, ScrollView, ActivityIndicator, TouchableHighlight, TouchableNativeFeedback, Platform } from 'react-native';

import styles from '../styles';

export default ({ captures=[], ocrDataList=[], showLines }) => {
  const TouchablePlatformSpecific = Platform.OS === 'ios' ? 
        TouchableHighlight : 
        TouchableNativeFeedback;

  return (
    <ScrollView>
      {captures.map(({ uri }, i) => (
        <View key={uri}>
          <TouchablePlatformSpecific onPress={() => showLines(i)} disabled={ocrDataList <= i}>
            <ImageBackground source={{ uri }} style={{ width: 75, height: 75 }}>
              { ocrDataList.length <= i &&
                <View style={[ styles.alignCenter, styles.galleryLoadingContainer ]}>
                  <ActivityIndicator size="large" color="#0000ff" />
                </View>
              }
            </ImageBackground>
          </TouchablePlatformSpecific>
        </View>
      ))}
    </ScrollView>
  );
};