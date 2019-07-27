import React from 'react';
import { View, ImageBackground, FlatList, ActivityIndicator, TouchableOpacity, Dimensions } from 'react-native';

import styles from '../styles';

const { width: winWidth, height: winHeight } = Dimensions.get('window');

// TODO: change this scrollview to flatlist
export default class Gallery extends React.Component {
  renderItem = ({ item, index }) => {
    const { ocrDataList, showLines } = this.props;

    // TODO: Change this. This won't work if the images are different sizes. 
    const width = winWidth / 4 - 4;
    const height = item.height * width / item.width;
    return (
      <View>
        <TouchableOpacity 
          style={{ flex: 1, flexDirection: 'column', width, height, margin: 1 }} 
          disabled={ocrDataList.length <= index} 
          onPress={() => showLines(index)}
        >
          <ImageBackground source={{ uri: item.uri }} style={{ width, height }} >
            { ocrDataList.length <= index &&
              <View style={[ styles.alignCenter, styles.galleryLoadingContainer ]}>
                <ActivityIndicator size="large" color="#0000ff" />
              </View>
            }
          </ImageBackground>
        </TouchableOpacity>
      </View>
    );
  };

  render() {
    const { captures, ocrDataList } = this.props;
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <FlatList
          keyExtractor={(item, index) => ''+index}
          data={captures}
          extraData={ocrDataList}
          renderItem={this.renderItem}
          numColumns={4}
        />
      </View>
    );
  };
};