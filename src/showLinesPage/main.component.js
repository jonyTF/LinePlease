import React from 'react';
import { View, Image, TouchableOpacity, Dimensions } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

const { width: winWidth, height: winHeight } = Dimensions.get('window');

export default({ 
  capture, curCharacters, linesByCharacter, cropTop, cropBot,
  nextLine, prevLine
}) => (
  <View>
    <Image 
      source={{uri: capture.uri}}
      style={{ 
        width: winHeight, 
        height: capture.height * winHeight/capture.width,
        position: 'absolute',  
        top: winWidth/2 - (cropBot-cropTop)/2 - cropTop,     
      }}
    />
    <TouchableOpacity 
      onPress={prevLine}
      activeOpacity={0.75}
      style={{
        position: 'absolute',
        left: 0,
        top: 0,
        width: winHeight,
        height: (winWidth - (cropBot-cropTop)) / 2,
      }}
    >
      <LinearGradient
        colors={['rgba(0, 0, 0, 0.9)', 'rgba(0, 0, 0, 0.5)']}
        style={{
          flex: 1,
        }}
      />
    </TouchableOpacity>
    
    <TouchableOpacity 
      onPress={nextLine}
      activeOpacity={0.75}
      style={{
        position: 'absolute',
        left: 0,
        top: (winWidth - (cropBot-cropTop)) / 2 + (cropBot-cropTop),
        width: winHeight,
        height: (winWidth - (cropBot-cropTop)) / 2,
      }}
    >
      <LinearGradient
        colors={['rgba(0, 0, 0, 0.5)', 'rgba(0, 0, 0, 0.9)']}
        style={{
          flex: 1,
        }}
      />
    </TouchableOpacity>

    {
      curCharacters.map((name, i) => {
        if (name in linesByCharacter) {
          return linesByCharacter[name].map((rect, j) => (
            <View 
              key={i + '_' + j}
              style={{
                backgroundColor: 'black',
                position: 'absolute',
                width: rect.width,
                height: rect.height,
                top: winWidth/2 - (cropBot-cropTop)/2 - cropTop + rect.top,
                left: rect.left
              }}
            />
          ));
        }
        return null;
      })
    }
  </View>
);