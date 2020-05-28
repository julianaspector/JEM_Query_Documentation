import cv2
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
%matplotlib inline
from PIL import Image
Image.MAX_IMAGE_PIXELS = None

import os
import random
import gc

train_dir = 'PATH TO TRAINING DIRECTORY HERE' # Original training directory: INSERT PATH TO train_all folder


train_docs = ['PATH TO TRAINING DIRECTORY HERE/{}'.format(i) for i in os.listdir(train_dir) if 'doc' in i]
train_maps = ['PATH TO TRAINING DIRECTORY HERE/{}'.format(i) for i in os.listdir(train_dir) if 'map' in i]


train_imgs = train_docs[:2000] + train_maps[:2000]
random.shuffle(train_imgs)

# clear lists that are useless
del train_docs
del train_maps
gc.collect()

import matplotlib.image as mpimg
for ima in train_imgs[0:3]:
        img=mpimg.imread(ima)
        imgplot = plt.imshow(img)
        plt.show()

nrows = 150
ncolumns = 150
channels= 3

def read_and_process_image(list_of_images):
    X  = [] #images
    y = [] # labels
    
    for image in list_of_images:
        X.append(cv2.resize(cv2.imread(image, cv2.IMREAD_COLOR), (nrows, ncolumns), interpolation=cv2.INTER_CUBIC))
        
        if 'doc' in image:
            y.append(1)
        elif 'map' in image:
            y.append(0)
            
    return(X,y)

X,y = read_and_process_image(train_imgs)


plt.figure(figsize=(20,10))
columns = 5
for i in range(columns):
    plt.subplot(5/columns + 1, columns, i + 1)
    plt.imshow(X[i])

import seaborn as sns
del train_imgs
gc.collect()

X = np.array(X)
y = np.array(y)

sns.countplot(y)
plt.title('Labels for Docs and Maps')

print("Shape of train images is:", X.shape)
print("Shape of labels is", y.shape)

from sklearn.model_selection import train_test_split
X_train, X_val, y_train, y_val = train_test_split(X, y, test_size = 0.8, random_state=2)

print('Shape of train images is', X_train.shape)
print('Shape of validation images is', X_val.shape)
print('Shape of labels is', y_val.shape)


del X
del y
gc.collect()

ntrain = len(X_train)
nval = len(X_val)

batch_size = 32

from keras import layers
from keras import models
from keras import optimizers
from keras.preprocessing.image import ImageDataGenerator
from keras.preprocessing.image import img_to_array, load_img

model = models.Sequential()
model.add(layers.Conv2D(32, (3,3), activation = 'relu', input_shape=(150, 150, 3)))
model.add(layers.MaxPooling2D((2,2)))
model.add(layers.Conv2D(64, (3,3), activation='relu'))
model.add(layers.MaxPooling2D((2,2)))
model.add(layers.Conv2D(128,(3,3), activation='relu'))
model.add(layers.MaxPooling2D((2,2)))
model.add(layers.Conv2D(128,(3,3), activation='relu'))
model.add(layers.MaxPooling2D((2,2)))
model.add(layers.Flatten())
model.add(layers.Dropout(0.5))
model.add(layers.Dense(512, activation='relu'))
model.add(layers.Dense(1, activation='sigmoid'))

#compile model
model.compile(loss='binary_crossentropy', optimizer=optimizers.RMSprop(lr=1e-4), metrics=['acc'])

train_datagen = ImageDataGenerator(rescale=1./255,
                                  rotation_range=40,
                                  width_shift_range=0.2,
                                  height_shift_range=0.2,
                                  shear_range=0.2,
                                  zoom_range=0.2,
                                  horizontal_flip=True)
val_datagen = ImageDataGenerator(rescale=1./255)


train_generator = train_datagen.flow(X_train, y_train, batch_size=batch_size)
val_generator = val_datagen.flow(X_val, y_val, batch_size=batch_size)

history=model.fit_generator(train_generator, 
                           steps_per_epoch=ntrain // batch_size,
                           epochs=64,
                           validation_data=val_generator,
                           validation_steps=nval // batch_size)

model.save_weights('model_weights.h5')
model.save('model_keras.h5')

test_dir = 'PATH TO TEST DIRECTORY HERE'
test_imgs = ['PATH TO TEST DIRECTORY HERE/{}'.format(i) for i in os.listdir(test_dir)]

i=0
text_labels = []
for batch in test_datagen.flow(x, batch_size=1):
    pred=model.predict(batch)
    if pred > 0.5:
        text_labels.append('doc')
    else:
        text_labels.append('map')
    i += 1
    if i == 309:
        break