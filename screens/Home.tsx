import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  StatusBar,
  Platform,
  BackHandler,
  Image,
} from 'react-native';

const Home = ({ title = 'group' }: { title?: string }) => {
  const handleBack = () => {
    BackHandler.exitApp();
  };

  return (
    <View style={styles.container}>
      {/* 设置 StatusBar 样式 */}
      <View style={styles.navBar}>
        <TouchableOpacity onPress={handleBack} style={styles.backButton}>
          {/* 可以换成你自己的返回图标 */}
          <Image
            source={require('../assets/border_close_grey.webp')} // 你需要提供这个图标
            style={styles.backIcon}
          />
        </TouchableOpacity>
        <Text style={styles.title}>{title}</Text>
        <View style={styles.rightPlaceholder} />
      </View>
      
    </View>
  );
};

const STATUS_BAR_HEIGHT = Platform.OS === 'ios' ? 44 : StatusBar.currentHeight || 24;
const NAV_BAR_HEIGHT = 56;

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#000000',
    paddingTop: 0,
  },
  navBar: {
    height: NAV_BAR_HEIGHT,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    borderBottomWidth: 0.5,
    borderColor: '#DDD',
  },
  backButton: {
    padding: 2,
    justifyContent: 'center',
    alignItems: 'center',
  },
  backIcon: {
    width: 24,
    height: 24,
    resizeMode: 'contain',
  },
  title: {
    fontSize: 18,
    fontWeight: '500',
    color: '#ffffff',
  },
  rightPlaceholder: {
    width: 32, // 占位符保持居中
  },
});

export default Home;
