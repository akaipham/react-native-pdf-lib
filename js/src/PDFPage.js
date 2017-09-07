/* @flow */

export default class PDFPage {
  page = {
    actions: [],
  };

  static create = () => {
    const newPage = new PDFPage();
    newPage.page.mediaBox = { x: 0, y: 0, width: 250, height: 500 };
    return newPage;
  }

  static modify = (pageIndex) => {
    const newPage = new PDFPage();
    newPage.page.pageIndex = pageIndex;
    return newPage;
  }

  setMediaBox = (width, height, options={}) => {
    if (this.page.pageIndex !== undefined) {
      throw new Error('Cannot set media box on modified page!');
    }
    this.page.mediaBox = {
      x: 0,
      y: 0,
      ...options,
      width,
      height,
    };
    return this;
  }

  drawText = (value, options={}) => {
    const textAction = {
      x: 0,
      y: 0,
      color: '#000000',
      fontSize: 12,
      ...options,
      type: 'text',
      value,
    };
    this.page.actions.push(textAction);
    return this;
  }

  // TODO: congpt - nhat
  drawSquarePoint = (options={}) => {
    console.log('Call drawSquarePoint');
    const rectAction = {
      x : 0,
      y : 0,
      edge: 5,
      color : '#000000',
      ...options,
      type: 'square_point'
    }
    this.page.actions.push(rectAction);
    return this;
  }

  drawCirclePoint = (options={}) => {
    console.log('Call drawCirclePoint');
    const circlePointAction = {
      x : 0,
      y : 0,
      radius: 5,
      color : '#000000',
      ...options,
      type: 'circle_point'
    }
    this.page.actions.push(circlePointAction);
    return this;
  }

  drawLine = (points, options={}) => {
    console.log('Call drawLine');
    const lineAction = {
      x : 0,
      y : 0,
      color : '#000000',
      strokeWidth: 2,
      points,
      ...options,
      type: 'line'
    }
    this.page.actions.push(lineAction);
    return this;
  }

  // drawLine = (points, options={}) => {
  //   console.log('Call drawLine');
  //   points.map(point => {
  //     drawCirclePoint({
  //       x: point.x,
  //       y: point.y,
  //       ...options
  //     });
  //   });
  //   this.page.actions.push(lineAction);
  //   return this;
  // }
  // END OF TODO

  drawRectangle = (options={}) => {
    const rectAction = {
      x: 0,
      y: 0,
      width: 50,
      height: 50,
      color: '#000000',
      ...options,
      type: 'rectangle',
    };
    this.page.actions.push(rectAction);
    return this;
  }

  drawImage = (imagePath, imageType, options={}) => {
    // TODO: Add logic using ReactNative.Image to automatically preserve image
    // dimensions!
    if (imageType !== 'jpg') {
      throw new Error('Only JPG images are currently supported!');
    }
    const imageAction = {
      x: 0,
      y: 0,
      ...options,
      type: 'image',
      imagePath,
      imageType,
    };
    this.page.actions.push(imageAction);
    return this;
  }
}
