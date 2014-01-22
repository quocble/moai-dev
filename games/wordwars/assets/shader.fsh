// Copyright (c) 2010-2011 Zipline Games, Inc. All Rights Reserved.
// http://getmoai.com

varying MEDP vec2 uvVarying;
varying LOWP vec4 colorVarying;

uniform sampler2D baseSampler;
uniform sampler2D maskSampler;
uniform sampler2D borderSampler;

void main() { 
	MEDP vec4 baseColor = texture2D ( baseSampler, uvVarying );
	MEDP vec4 maskColor = texture2D ( maskSampler, uvVarying);
	MEDP vec4 borderColor = texture2D ( borderSampler, uvVarying);	
	gl_FragColor =  borderColor + (baseColor * maskColor);
}
