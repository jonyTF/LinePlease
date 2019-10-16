import React from 'react';
import { View, ImageBackground, FlatList, ActivityIndicator, TouchableOpacity, Dimensions } from 'react-native';

import styles from '../styles';

const { width: winWidth, height: winHeight } = Dimensions.get('window');

// TODO: change this scrollview to flatlist
export default class Gallery extends React.Component {
  renderItem = ({ item, index }) => {
    const { showLines } = this.props;
    console.log('yes: ', item.ocrData == null);

    // TODO: Change this. This won't work if the images are different sizes. 
    const width = winWidth / 4 - 4;
    const height = item.capture.height * width / item.capture.width;
    
    return (
      <View>
        <TouchableOpacity 
          style={{ flex: 1, flexDirection: 'column', width, height, margin: 1 }} 
          disabled={item.ocrData == null} 
          onPress={() => showLines(index)}
        >
          <ImageBackground source={{ uri: item.capture.uri }} style={{ width, height }} >
            { item.ocrData == null &&
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
    const { data } = this.props;
    console.log('no: ', data[0].ocrData == null);
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <FlatList
          keyExtractor={(item, index) => ''+index}
          data={data}
          renderItem={this.renderItem}
          numColumns={4}
          legacyImplementation={true}
        />
      </View>
    );
  };
};