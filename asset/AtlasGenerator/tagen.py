'''
Created on 25.11.2012

implementation of the texture packing algorithm proposed by Jim Scott in 
http://www.blackpawn.com/texts/lightmaps/default.html


Copyright 2012 Peter Melchart

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

'''

import os
import sys
import Image
import math
import json
from xml.dom.minidom import getDOMImplementation

class Rect(object):
    x,y,w,h=0,0,0,0
    
    def __init__(self, x, y, w, h):
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        
    def compare(self, size, allow_rotation):
        '''
        returns
            -1 if the rect is smaller than the rect of the given size
            0 if the rect matches exactly the rect of the given size
            1 if the rect is bigger than the rect of the given size
        '''
        
        if self.w==size[0] and self.h==size[1]:
            return 0,False
        if allow_rotation and self.w==size[1] and self.h==size[0]:
            return 0,True
        if self.w>=size[0] and self.h>=size[1]:
            return 1,False
        if allow_rotation and self.w>=size[1] and self.h>=size[0]:
            return 1,True
        return -1,False

class Node(object):
    def __init__(self, x,y,w,h):
        self.children = None
        self.rect = Rect(x,y,w,h)
        self.texture = None
        self.rotated = False

    
    def insert(self, size, allow_rotation):
        # are we a branch?
        if self.children:
            newnode, rotated = self.children[0].insert(size, allow_rotation)
            if newnode:
                return newnode, rotated
            return self.children[1].insert(size, allow_rotation)
        
        # already texture there?
        if self.texture:
            return None, False

        # this node too small?
        status, rotated = self.rect.compare(size, allow_rotation)
        if status < 0:
            # too small
            return None, False
        
        if status == 0:
            # matches exactly
            return self, rotated
        
        # rect is bigger. so lets split it        
        
        imgw = (size[1] if rotated else size[0])
        imgh = (size[0] if rotated else size[1])
        
        dw = self.rect.w - imgw
        dh = self.rect.h - imgh
        
        r = self.rect
        if dw > dh:
            self.children = [Node(r.x, r.y, imgw, r.h), \
                             Node(r.x+imgw, r.y, r.w-imgw, r.h)]
        else:
            self.children = [Node(r.x, r.y, r.w, imgh), \
                             Node(r.x, r.y+imgh, r.w, r.h-imgh)]
        
        return self.children[0].insert(size, allow_rotation)

    def render(self, image, padding, fill=True):
        maxx, maxy = 0,0
        
        if self.texture:
            thisimage = Image.open(self.texture)
            if self.rotated:
                thisimage = thisimage.rotate(90)
            w,h = thisimage.size            
            rx = self.rect.x
            ry = self.rect.y
            rh = self.rect.h
            rw = self.rect.w
            image.paste(thisimage, (rx+padding, ry+padding))
            
            maxx += rx+rw
            maxy += ry+rh
            
            if fill:
                #top
                part = thisimage.crop((0,0,w,1))
                part = part.resize((w,padding))
                image.paste(part, (rx+padding,ry))

                #topleft
                part = thisimage.crop((0,0,1,1))
                part = part.resize((padding,padding))
                image.paste(part, (rx,ry))

                #topright
                part = thisimage.crop((w-1,0,w,1))
                part = part.resize((padding,padding))
                image.paste(part, (rx+rw-padding,ry))

                #bottom
                part = thisimage.crop((0,h-1,w,h))
                part = part.resize((w,padding))
                image.paste(part, (rx+padding,ry+rh-padding))

                #left
                part = thisimage.crop((0,0,1,h))
                part = part.resize((padding,h))
                image.paste(part, (rx,ry+padding))

                #bottomleft
                part = thisimage.crop((0,h-1,1,h))
                part = part.resize((padding,padding))
                image.paste(part, (rx,ry+rh-padding))

                #bottomright
                part = thisimage.crop((w-1,h-1,w,h))
                part = part.resize((padding,padding))
                image.paste(part, (rx+rw-padding,ry+rh-padding))
                
                #right
                part = thisimage.crop((w-1,0,w,h))
                part = part.resize((padding,h))
                image.paste(part, (rx+rw-padding,ry+padding))

        
        if self.children:
            x1, y1 = self.children[0].render(image, padding, fill)
            x2, y2 = self.children[1].render(image, padding, fill)
            maxx = max(maxx, x1, x2)
            maxy = max(maxy, y1, y2)
            
        return maxx, maxy
        
    def calc_area(self):
        area = 0
        if self.texture:
            area += self.rect.w * self.rect.h
        if self.children:
            area += self.children[0].calc_area()        
            area += self.children[1].calc_area()
        return area

        

class Generator(object):
    IMAGE_TYPES = [".png", ".jpg", ".jpeg"]
    INFO_CSV = "csv"
    INFO_XML = "xml"
    INFO_JSON = "json"


    def __init__(self):
        self._texture_info = dict()
        self._atlas_info = dict()
    
    def collect(self, root_folder):
        self._texture_info = dict()
        self._atlas_info = dict()
        
        self._root_folder = root_folder
        self._groups = dict()
        for folder, _, filenames in os.walk(root_folder):
            filenames = [os.path.join(folder, fn) for fn in filenames if os.path.splitext(os.path.join(folder, fn))[1].lower() in Generator.IMAGE_TYPES]
            if filenames:
                for filename in filenames:
                    image = Image.open(filename)
                    self._texture_info[filename] = dict(size=image.size)

                if self._group_by_folder:
                    self._groups[folder if self._group_by_folder else ""] = filenames
                else:
                    if "" not in self._groups:
                        self._groups[""]=[]
                    self._groups[""].extend(filenames)
            
    def _image_sort_func(self, a, b):
        size1 = self._texture_info[a]["size"]
        size2 = self._texture_info[b]["size"]
        val1 = size1[0]*size1[1]
        val2 = size2[0]*size2[1]
        return cmp(val1,val2) if self._sort==1 else cmp(val2,val1)
            

    def log2(self, d):
        return math.log(d)/math.log(2)
    
    def _is_po2(self, d):
        return ((math.log(d)/math.log(2))%1.0)==0

    def _post_process(self, image, maxx, maxy):
        '''
        crop the image if wanted and enforce power-of-2-ness if wanted
        
        '''
        
        w, h = image.size
        w2, h2 = self._is_po2(w), self._is_po2(h)
        # if image is already power of two and no cropping os requested, just return passed image
        if not self._crop and w2 and h2:
            return image
        
        next_po2_width = int(2**(math.ceil(self.log2(maxx))))
        next_po2_height = int(2**(math.ceil(self.log2(maxy))))
        
        new_width = next_po2_width if self._po2 else maxx
        new_height = next_po2_height if self._po2 else maxy
        
        newimage = Image.new(image.mode, (new_width, new_height))
        image = image.crop((0,0,maxx, maxy))
        newimage.paste(image, (0,0))
        return newimage
            
        
        
        
    
    
    def create(self, outfolder):
        texSize = self._texture_size
        
        if self._verbose:
            print "Creating texture atlases with size:",texSize        
        atlas_number = 1
        for group, images in self._groups.items():                            
            if self._sort == 0:
                images_scheduled = images
            else:
                images_scheduled = sorted(images, cmp=lambda a,b:self._image_sort_func(a, b))
                
            while True:
                if self._flatten_output or not self._group_by_folder:
                    outpath = os.path.join(outfolder, "atlas%02d.png" % atlas_number)
                else:
                    outpath = os.path.join(outfolder, os.path.relpath(group, self._root_folder), "atlas%02d.png" % atlas_number)
                    
                self._atlas_info[outpath] = dict()
                
                texWidth = texSize
                texHeight = texSize

                last_root = None                
                if self._verbose:
                    if group and group!="":
                        print "group",group
                print "atlas #",atlas_number
                while True:
                    root = Node(0,0,texWidth, texHeight)
                    next_scheduled = []
                    if self._verbose:
                        print "trying size %dx%d"%(texWidth, texHeight)
                    for imagepath in images_scheduled:
                        size = self._texture_info[imagepath]["size"]
                        size = [size[0]+self._padding*2, size[1]+self._padding*2]
                        node, rotated = root.insert(size, self._allow_rotation)
                        if node:
                            node.texture = imagepath
                            node.rotated = rotated                     
                            self._texture_info[imagepath]["atlas"] = outpath
                            self._atlas_info[outpath][imagepath] = dict(rect=node.rect, rotated=rotated)
                        else:
                            next_scheduled.append(imagepath)
                        
                    used_area = root.calc_area()
                    total_area = texWidth*texHeight
                    
                    if self._verbose:
                        print "coverage = %d%%"%int(100*used_area/total_area)
                    if not self._optimize or used_area==0 or used_area > total_area*0.5:
                        break
                    
                    if texWidth == texHeight:
                        texHeight /= 2
                    else:
                        texWidth /= 2
                        
                    if texWidth == 1 or texHeight == 1:
                        if self._verbose:
                            print "aborting optimization. taking original"
                        root = last_root
                        break
                    
                    if last_root is None:
                        last_root = root
                    
                    
                        
                
                
                        
                if images_scheduled == next_scheduled:
                    # all the following images are too big to fit on a single texture with the given max size
                    for imagepath in images_scheduled:
                        print "cannot fit in",imagepath
                    break
                                                
                image = Image.new("RGBA", (texWidth, texHeight))
                maxx, maxy = root.render(image, self._padding, self._fill)
                image = self._post_process(image, maxx, maxy)
                
                try:    os.makedirs(os.path.dirname(outpath))
                except: pass
                image.save(outpath, optimize=True)
                       
                self.write_info_file(self._atlas_info[outpath], os.path.splitext(outpath)[0]+".info")         
                
                images_scheduled = next_scheduled
                atlas_number += 1
                

    def _write_csv_info_file(self, info, outpath):
        with open(outpath, "wt") as outfile:
            outfile.write("path;x1;y1;x2;y2\n")
            for path, entry in info.items():
                rect = entry["rect"]
                rotated = entry["rotated"]
                x, y, w, h = rect.x, rect.y, rect.w, rect.h
                outfile.write(path)
                outfile.write(";")
                outfile.write("%d;%d;%d;%d;%s" % (x, y, x + w - 1, y + h - 1, rotated))
                outfile.write("\n")

    def _write_xml_info_file(self, info, outpath):
        impl = getDOMImplementation()
        newdoc = impl.createDocument(None, "textures", None)
        top_element = newdoc.documentElement
        
        with open(outpath, "wt") as outfile:
            for path, entry in info.items():
                rect = entry["rect"]
                rotated = entry["rotated"]
                x, y, w, h = rect.x, rect.y, rect.w, rect.h
                
                node = newdoc.createElement("texture")
                node.setAttribute("path", path)
                node.setAttribute("x1",str(x))
                node.setAttribute("y1",str(y))
                node.setAttribute("x2",str(x+w-1))
                node.setAttribute("y2",str(y+h-1))
                node.setAttribute("rotated", str(rotated))
                top_element.appendChild(node)

            outfile.write(newdoc.toprettyxml())

    def _write_json_info_file(self, info, outpath):
        with open(outpath, "wt") as outfile:
            o = []
            for path, entry in info.items():
                rect = entry["rect"]
                rotated = entry["rotated"]
                x, y, w, h = rect.x, rect.y, rect.w, rect.h
                o.append(dict(path=path,x1=x,y1=y,x2=x+w-1,y2=y+h-1,rotated=rotated))
            outfile.write(json.dumps(o, indent=4))

    def write_info_file(self, info, outpath):
        if self._info_format == Generator.INFO_CSV:        
            self._write_csv_info_file(info, outpath)
        elif self._info_format == Generator.INFO_XML:        
            self._write_xml_info_file(info, outpath)
        elif self._info_format == Generator.INFO_JSON:        
            self._write_json_info_file(info, outpath)
        else:
            raise ValueError("illegal info format:",self._info_format)


    def set_options(self, options):
        self.__options = options
        self._verbose = options.verbose
        self._texture_size = options.texture_size
        self._flatten_output = options.flat
        self._group_by_folder = options.group_by_folder
        self._sort = options.sort
        self._padding = options.padding
        self._fill = options.fill
        self._optimize = options.optimize
        self._po2 = options.power_of_two
        self._crop = options.crop
        self._info_format = options.info
        self._allow_rotation = not options.no_rotation

if __name__ == '__main__':
    import optparse
    parser = optparse.OptionParser(usage="usage: %prog [options] infolder outfolder")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="verbose mode")
    parser.add_option("-t", "--texture", dest="texture_size", action="store", default=1024, type=int, help="texture atlas size")
    parser.add_option("-g", "--group_by_folder", dest="group_by_folder", action="store_true", default=False, help="if specified, create texture atlases per folder. output will also get flattened.")    
    parser.add_option("-f", "--flat", dest="flat", action="store_true", default=False, help="if specified, the folder structure will NOT be re-created in the output folder.")    
    parser.add_option("-s", "--sort", dest="sort", action="store", default=-1, type=int, help="sort for size: -1=descending, 1=ascending, 0=no sort. default:-1")    
    parser.add_option("-p", "--padding", dest="padding", action="store", default=0, type=int, help="padding for each sub texture.")    
    parser.add_option("", "--fill", dest="fill", action="store_true", default=False, help="if set, fill padded areas with border of sub texture to reduce texturing artifacts (seams)")
    parser.add_option("-c", "--crop", dest="crop", action="store_true", default=False, help="if set, any overhead on the texture will be cropped ( will result in non-PO2 textures unless --power_of_two is set")    
    parser.add_option("-2", "--power_of_2", dest="power_of_two", action="store_true", default=False, help="output of a power of two texture is enforced")    
    parser.add_option("-o", "--optimize", dest="optimize", action="store_true", default=False, help="if specified, atlases with a lot of empty space will be re-generated using smaller dimensions")
    parser.add_option("-i", "--info", dest="info", action="store", default="csv", help="output format of the info file (xml, json, csv). default: csv")
    parser.add_option("-n", "--no_rotation", dest="no_rotation", action="store_true", default=False, help="output format of the info file (xml, json, csv). default: csv")
    options, args = parser.parse_args()
    
    try:
        infolder, outfolder = args
    except:
        parser.print_version()
        sys.exit(-1)

    g = Generator()
    g.set_options(options)
    g.collect(infolder)
    g.create(outfolder)
