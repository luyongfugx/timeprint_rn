import React from 'react';
import { View, StyleSheet, Image, TouchableOpacity, SafeAreaView } from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { X } from 'lucide-react-native';

const PhotoViewScreen = () => {
  const route = useRoute();
  const navigation = useNavigation();
  const { photoUrl } = route.params as { photoUrl: string };

  return (
    <SafeAreaView style={styles.container}>
      <TouchableOpacity 
        style={styles.closeButton}
        onPress={() => navigation.goBack()}
      >
        <X size={24} color="white" />
      </TouchableOpacity>
      
      <Image 
        source={{ uri: photoUrl }} 
        style={styles.image}
        resizeMode="contain"
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'black',
    justifyContent: 'center',
    alignItems: 'center',
  },
  image: {
    width: '100%',
    height: '100%',
  },
  closeButton: {
    position: 'absolute',
    top: 20,
    right: 20,
    zIndex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderRadius: 20,
    padding: 10,
  },
});

export default PhotoViewScreen;
