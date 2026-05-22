function [out] = paint_image_3(final_colors, image,n,m, n_relevant,file_name)

    for pixel_index = 1:size(image,1)
        expanded_pixel = repmat(image(pixel_index,:),[n_relevant,1]);
        distance_aux = deltaE00_mod(expanded_pixel,final_colors);
        [~, closest_index] = min(distance_aux);
        image(pixel_index,:) = final_colors(closest_index,:);
    end
    out = reshape(lab2rgb(image),[n,m,3]);
    imwrite(reshape(lab2rgb(image),[n,m,3]),file_name)
end
