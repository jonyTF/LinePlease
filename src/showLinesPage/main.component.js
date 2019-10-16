import React from 'react';
import { View, Image, TouchableOpacity, Dimensions, Animated } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

const { width: winWidth, height: winHeight } = Dimensions.get('window');
const AnimatedTouchableOpacity = Animated.createAnimatedComponent(TouchableOpacity);

export default({ 
  capture, curCharacters, linesByCharacter, cropTop, cropBot, imageX,
  nextLine, prevLine
}) => {
  //  winWidth/2 - (cropBot-cropTop)/2 - cropTop
  const imTop = Animated.subtract(Animated.subtract(winWidth/2, Animated.divide(Animated.subtract(cropBot, cropTop), 2)), cropTop);
  // (winWidth - (cropBot._value-cropTop._value)) / 2
  const boxHeight = Animated.divide(Animated.subtract(winWidth, Animated.subtract(cropBot, cropTop)), 2);
  // (winWidth - (cropBot._value-cropTop._value)) / 2 + (cropBot._value-cropTop._value)
  const boxBotTop = Animated.add(boxHeight, Animated.subtract(cropBot, cropTop));
  
  return (
    <View>
      <Animated.Image 
        source={{uri: capture.uri}}
        style={{ 
          width: winHeight+20, 
          height: capture.height * winHeight/capture.width,
          position: 'absolute',  
          top: imTop,   
          left: 0,  
        }}
      />
      <AnimatedTouchableOpacity 
        onPress={prevLine}
        activeOpacity={0.75}
        style={{
          position: 'absolute',
          left: 0,
          top: 0,
          width: winHeight,
          height: boxHeight,
        }}
      >
        <LinearGradient
          colors={['rgba(0, 0, 0, 0.9)', 'rgba(0, 0, 0, 0.5)']}
          style={{
            flex: 1,
          }}
        />
      </AnimatedTouchableOpacity>
      
      <AnimatedTouchableOpacity 
        onPress={nextLine}
        activeOpacity={0.75}
        style={{
          position: 'absolute',
          left: 0,
          top: boxBotTop,
          width: winHeight,
          height: boxHeight,
        }}
      >
        <LinearGradient
          colors={['rgba(0, 0, 0, 0.5)', 'rgba(0, 0, 0, 0.9)']}
          style={{
            flex: 1,
          }}
        />
      </AnimatedTouchableOpacity>

      {/*
        curCharacters.map((name, i) => {
          if (name in linesByCharacter) {
            return linesByCharacter[name].map((rect, j) => (
              <Animated.View 
                key={i + '_' + j}
                style={{
                  backgroundColor: 'black',
                  position: 'absolute',
                  width: rect.width,
                  height: rect.height,
                  top: winWidth/2 - (cropBot._value-cropTop._value)/2 - cropTop._value + rect.top,
                  left: rect.left
                }}
              />
            ));
          }
          return null;
        })
        */
      }
    </View>
  );
};
