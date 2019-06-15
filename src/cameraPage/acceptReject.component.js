import React from 'react';
import { Col, Row, Grid } from 'react-native-easy-grid';
import { TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import styles from '../styles';

export default ({savePhotoData, discardPhotoData}) => (
  <Grid style={styles.bottomToolbar}>
    <Row>
      <Col style={styles.alignCenter}>
        <TouchableOpacity onPress={discardPhotoData}>
          <Ionicons 
            name="md-close"
            color="white"
            size={30}
          />
        </TouchableOpacity>
      </Col>
      <Col style={styles.alignCenter}>
        <TouchableOpacity onPress={savePhotoData} style={styles.acceptBtn}>
          <Ionicons 
            name="md-checkmark"
            color="white"
            size={30}
          />
        </TouchableOpacity>
      </Col>
    </Row>
  </Grid>
);