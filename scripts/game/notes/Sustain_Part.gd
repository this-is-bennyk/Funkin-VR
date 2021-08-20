#tool
extends Node2D

export(Texture) var line_segment
export(Texture) var endcap

# Format: length, was_hit

var segments = []

var original_line_length
var original_segment_length

func _process(delta):
	update()

func _draw():
	var segment_rect = Rect2(0, 0, line_segment.get_size().x, line_segment.get_size().y)
	var endcap_rect = Rect2(0, 0, endcap.get_size().x, endcap.get_size().y)
	var y_pos = 0
	
	for segment in segments:
		var color = Color(1.0, 1.0, 1.0, 0.5)
		if segment[1]:
			color = Color.transparent
		
		if y_pos <= original_segment_length:
			segment_rect.position.y = line_segment.get_size().y * (y_pos / original_segment_length)
			segment_rect.size.y = line_segment.get_size().y - segment_rect.position.y
			
			if y_pos + segment[0] <= original_segment_length:
				draw_texture_rect_region(line_segment,
										 Rect2(-segment_rect.size.x / 2.0, y_pos, segment_rect.size.x, segment[0]),
										 segment_rect,
										 color)
			else:
				draw_texture_rect_region(line_segment,
										 Rect2(-segment_rect.size.x / 2.0, y_pos, segment_rect.size.x, original_segment_length - y_pos),
										 segment_rect,
										 color)
				
				draw_texture_rect_region(endcap,
										 Rect2(-endcap_rect.size.x / 2.0, original_segment_length, endcap_rect.size.x, y_pos + segment[0] - original_segment_length),
										 endcap_rect,
										 color)
		else:
			endcap_rect.position.y = endcap.get_size().y * ((y_pos - original_segment_length) / (original_line_length - original_segment_length))
			endcap_rect.size.y = endcap.get_size().y - endcap_rect.position.y
			
			draw_texture_rect_region(endcap,
									 Rect2(-segment_rect.size.x / 2.0, y_pos, segment_rect.size.x, segment[0]),
									 endcap_rect,
									 color)
		
		y_pos += segment[0]
	
	if y_pos <= original_segment_length:
		segment_rect.position.y = line_segment.get_size().y * (y_pos / original_segment_length)
		segment_rect.size.y = line_segment.get_size().y - segment_rect.position.y
		
		draw_texture_rect_region(line_segment,
								 Rect2(-segment_rect.size.x / 2.0, y_pos, segment_rect.size.x, original_segment_length - y_pos),
								 segment_rect,
								 Color(1.0, 1.0, 1.0, 0.5))
		
		draw_texture_rect(endcap,
						  Rect2(-endcap.get_size().x / 2.0, original_segment_length, endcap.get_size().x, endcap.get_size().y),
						  false,
						  Color(1.0, 1.0, 1.0, 0.5))
	
	elif y_pos <= original_line_length:
		endcap_rect.position.y = endcap.get_size().y * ((y_pos - original_segment_length) / (original_line_length - original_segment_length))
		endcap_rect.size.y = endcap.get_size().y - endcap_rect.position.y
		
		draw_texture_rect_region(endcap,
								 Rect2(-endcap.get_size().x / 2.0, y_pos, endcap.get_size().x, original_line_length - y_pos),
								 endcap_rect,
								 Color(1.0, 1.0, 1.0, 0.5))

func get_total_segments_length():
	if segments.size() == 0:
		return 0
	else:
		var length = 0
		
		for segment in segments:
			length += segment[0]
		
		return length
