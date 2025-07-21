import React from 'react';
import { View, Modal, ScrollView } from 'react-native';
import { Title, Paragraph, Button } from 'react-native-paper';
import { colors } from '../theme';

const CustomModal = ({ 
  visible, 
  onClose, 
  title, 
  message, 
  buttonText = 'OK',
  onButtonPress,
  customContent 
}) => {
  const handleButtonPress = () => {
    if (onButtonPress) {
      onButtonPress();
    }
    onClose();
  };

  return (
    <Modal
      visible={visible}
      transparent={true}
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={styles.modalOverlay}>
        <View style={styles.modalContent}>
          {customContent ? (
            <ScrollView contentContainerStyle={styles.customContentContainer}>
              {customContent}
            </ScrollView>
          ) : (
            <>
              <Title style={styles.modalTitle}>{title}</Title>
              <Paragraph style={styles.modalMessage}>{message}</Paragraph>
              <Button
                mode="contained"
                onPress={handleButtonPress}
                style={styles.modalButton}
              >
                {buttonText}
              </Button>
            </>
          )}
        </View>
      </View>
    </Modal>
  );
};

const styles = {
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 24,
    margin: 20,
    maxHeight: '80%',
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  customContentContainer: {
    flexGrow: 1,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: colors.error || '#d32f2f',
    marginBottom: 16,
    textAlign: 'center',
  },
  modalMessage: {
    fontSize: 16,
    color: colors.text,
    marginBottom: 24,
    textAlign: 'center',
    lineHeight: 22,
  },
  modalButton: {
    paddingVertical: 8,
  },
};

export default CustomModal; 