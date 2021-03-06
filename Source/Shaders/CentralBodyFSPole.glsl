uniform sampler2D u_fbTexture;
uniform vec3 u_color;

varying vec2 v_textureCoordinates;

void main()
{
    vec4 color = texture2D(u_fbTexture, v_textureCoordinates);
    if (color.a == 1.0)
        discard;
    
    // TODO: make arbitrary ellipsoid
    czm_ellipsoid ellipsoid = czm_getWgs84EllipsoidEC();
    vec3 direction = normalize(czm_windowToEyeCoordinates(gl_FragCoord).xyz);
    czm_ray ray = czm_ray(vec3(0.0), direction);
    czm_raySegment intersection = czm_rayEllipsoidIntersectionInterval(ray, ellipsoid);
    
    if (!czm_isEmpty(intersection))
    {
        vec3 positionEC = czm_pointAlongRay(ray, intersection.start);
        vec3 positionMC = (czm_inverseModelView * vec4(positionEC, 1.0)).xyz;
	    
	    vec3 normalMC = normalize(czm_geodeticSurfaceNormal(positionMC, vec3(0.0), vec3(1.0)));
	    vec3 normalEC = normalize(czm_normal * normalMC);
	    
	    AtmosphereColor atmosphereColor = computeGroundAtmosphereFromSpace(positionMC);
	    vec3 mieColor = atmosphereColor.mie;
        vec3 rayleighColor = atmosphereColor.rayleigh;
        
#ifdef SHOW_DAY    
        vec3 startDayColor = u_color;
#else
        vec3 startDayColor = vec3(1.0);
#endif
		
#ifdef AFFECTED_BY_LIGHTING
        vec3 rgb = getCentralBodyColor(positionMC, positionEC, normalMC, normalEC, startDayColor, rayleighColor, mieColor);
#else
        vec3 rgb = startDayColor;
#endif

        gl_FragColor = vec4(rgb, 1.0);
    }
    else
    {
        discard;
    }
}