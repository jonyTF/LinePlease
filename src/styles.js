import { StyleSheet, Dimensions } from 'react-native';

const { width: winWidth, height: winHeight } = Dimensions.get('window');

export default StyleSheet.create({
  preview: {
    position: 'absolute',
    left: 0,
    top: 0,
    right: 0,
    bottom: 0,
  },
  alignCenter: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  bottomToolbar: {
    width: winWidth,
    position: 'absolute',
    height: 100,
    bottom: 0,
  },
  captureBtn: {
    width: 62,
    height: 62,
    backgroundColor: '#dddddd',
    borderWidth: 4,
    borderRadius: 100,
    borderColor: '#ffffff',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
  },
  captureBtnActive: {
    borderWidth: 6,
  },
  galleryContainer: {
    bottom: 100,
  },
  galleryImageContainer: {
    width: 75,
    height: 75,
    marginRight: 5,
  },
  galleryImage: {
    width: 75,
    height: 75,
  },
  acceptBtn: {
    width: 62,
    height: 62,
    backgroundColor: '#1F85DE',
    borderRadius: 100,
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
  },
  leftTopBtn: {
    position: 'absolute',
    left: 25,
    top: 25,
  },
  rightTopBtn: {
    position: 'absolute',
    right: 25,
    top: 25,
  },
  btnText: {
    color: 'white',
    fontSize: 15,
  },
  btn: {
    margin: 10
  },
  galleryLoadingContainer: {
    backgroundColor: 'rgba(255, 255, 255, 0.5)', 
    width: '100%', 
    height: '100%',
  }
});