
# Image_Entropy_Filtering_Script.py
# J. Spector, 5/22/2020
# Purpose: This script filters images based on image entropy to identify those likely to be maps. 
# Images confirmed to be maps by user are then saved in a specified directory.

# import necessary libraries
from skimage import io
import os
import numpy as np
from skimage.measure import shannon_entropy
import matplotlib.pyplot as plt
from PIL import Image # necessary for controlling save image quality as jpeg

img_directory = '' # Enter path for directory with images to be processed with forward slashes between folders
dest_directory = '' # Enter path for directory for map images to be copied to after processing

# calculate entropy for each image in directory
# this can take awhile, depending on number of images, so might consider separating your images into batches
entropy_list = []
for file in os.listdir(img_directory):
    if file.endswith(".jpeg"):
        image = io.imread(os.path.join(img_directory, file))
        E = shannon_entropy(image, base=2)
        entropy_list.append(E)

 index=[index for index, value in enumerate(entropy_list) if value > 4.4] # 4.4 was chosen based on testing and seeing what threshold 
 																		#brought back most map images with minimal documents, but this value can be fine-tuned

# create list of file locations
locations = []
files = os.listdir(img_directory)
for file in files:
    locations.append(os.path.join(img_directory, file))


 # create arrays for images of interest 
image_arrays = []
for i in index:
    image_arrays.append(io.imread(os.path.join(locations[i])))

# function to show images with image index in directory as title
# Based on: https://gist.github.com/soply/f3eec2e79c165e39c9d540e916142ae1

 def show_images(images, cols = 1, titles = index):
    """Display a list of images in a single figure with matplotlib.
    
    Parameters
    ---------
    images: List of np.arrays compatible with plt.imshow.
    
    cols (Default = 1): Number of columns in figure (number of rows is 
                        set to np.ceil(n_images/float(cols))).
    
    titles: List of titles corresponding to each image. Must have
            the same length as titles.
    """
    assert((titles is None)or (len(images) == len(titles)))
    n_images = len(images)
    if titles is None: titles = ['Image (%d)' % i for i in range(1,n_images + 1)]
    fig = plt.figure()
    for n, (image, title) in enumerate(zip(images, titles)):
        a = fig.add_subplot(cols, np.ceil(n_images/float(cols)), n + 1)
        if image.ndim == 2:
            plt.gray()
        plt.imshow(image)
        a.set_title(title)
    fig.set_size_inches(np.array(fig.get_size_inches()) * n_images)
    plt.show()

# execute function
# this function can be slow depending on number of images to be displayed. 
# May consider splitting images into batches for processing.
show_images(image_arrays)

# enter index numbers of the images you want to save
savedImages = []

# save images in destination directory
for i in savedImages:
    filenames = locations[i][-15:-5]
    filenames = filenames.replace("/", "")
    io.imsave(os.path.join(dest_directory, filenames +".jpeg"),io.imread(locations[i]), quality=100)																