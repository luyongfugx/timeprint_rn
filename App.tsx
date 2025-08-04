/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */
import * as React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import Ionicons from 'react-native-vector-icons/Ionicons'; // 需要安装 react-native-vector-icons
import { Users, Chrome as Home,Settings } from 'lucide-react-native';
// 引入你创建的页面组件
import HomeScreen from './screens/HomeScreen';
import MembersManagement from './screens/members';
import ProfileScreen from './screens/ProfileScreen';

const Tab = createBottomTabNavigator();

function App() {
  return (
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={({ route }) => ({
          tabBarIcon: ({ focused, color, size }) => {
            let icon;

            if (route.name === 'Home') {
              icon = focused ? <Home size={size} color={color} /> : <Home size={size} color={color} />;    
            } else if (route.name === 'Member') {
              icon = focused ? <Users size={size} color={color} /> : <Users size={size} color={color} />;
            } else if (route.name === 'Profile') {
              icon = focused ? <Settings size={size} color={color} />  : <Settings size={size} color={color} />;
            }

            // You can return any component that you like here!
            return icon;
          },
          tabBarActiveTintColor: 'tomato', // 选中时的 Tab 颜色
          tabBarInactiveTintColor: 'gray', // 未选中时的 Tab 颜色
          headerShown: false, // 隐藏 Tab 页面自身的头部
        })}
      >
        <Tab.Screen name="Home" component={HomeScreen} options={{ title: '首页' }} />
        <Tab.Screen name="Member" component={MembersManagement} options={{ title: '成员' }} />
        <Tab.Screen name="Profile" component={ProfileScreen} options={{ title: '我的' }} />
      </Tab.Navigator>
    </NavigationContainer>
  );
}

export default App;
