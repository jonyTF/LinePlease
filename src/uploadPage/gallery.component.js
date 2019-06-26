import React from 'react';
import { View, ImageBackground, ScrollView, ActivityIndicator, TouchableOpacity } from 'react-native';

import styles from '../styles';

// TODO: change this scrollview to flatlist
export default ({ captures=[], ocrDataList=[], showLines }) => (
  <ScrollView>
    {captures.map(({ uri }, i) => (
      <View key={uri}>
        <TouchableOpacity onPress={() => showLines(i)} disabled={ocrDataList <= i}>
          <ImageBackground source={{ uri }} style={{ width: 75, height: 75 }}>
            { ocrDataList.length <= i &&
              <View style={[ styles.alignCenter, styles.galleryLoadingContainer ]}>
                <ActivityIndicator size="large" color="#0000ff" />
              </View>
            }
          </ImageBackground>
        </TouchableOpacity>
      </View>
    ))}
  </ScrollView>
);