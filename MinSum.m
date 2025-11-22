iterations = 80;
lambda = 5;
threshold = 2;
dispLevels = 16;

% Δημιούργησε τις τιμές των παραλλάξεων
d = 0:dispLevels-1;

% Διάβασε τις εικόνες και μετέτρεψέ τες σε εικόνες κλίμακας του γκρι
left = rgb2gray(imread('Left.png'));
right = rgb2gray(imread('Right.png'));

% Εφάρμοσε ένα γκαουσιανό φίλτρο στις εικόνες
left = imgaussfilt(left,0.6,'FilterSize',5);
right = imgaussfilt(right,0.6,'FilterSize',5);

% Πάρε τις διαστάσεις των εικόνων
[height,width] = size(left);

% Υπολόγισε το data cost
dataCost = zeros(height,width,dispLevels);
for i = 1:dispLevels
	right_d = [zeros(height,d(i)),right(:,1:end-d(i))];
	dataCost(:,:,i) = abs(double(left)-double(right_d));
end

% Υπολόγισε το smoothness cost
smoothnessCost = lambda*min(abs(d-d'),threshold);

% Αρχικοποίησε τα μηνύματα στην τιμή μηδέν
msgUp = zeros(height,width,dispLevels);
msgDown = zeros(height,width,dispLevels);
msgRight = zeros(height,width,dispLevels);
msgLeft = zeros(height,width,dispLevels);

figure

% Ξεκίνα τις επαναλήψεις
for i = 1:iterations
	% Βοηθητικοί πίνακες για τον υπολογισμό των μηνυμάτων
	U = dataCost + msgDown + msgRight + msgLeft;
	D = dataCost + msgUp + msgRight + msgLeft;
	R = dataCost + msgUp + msgDown + msgLeft;
	L = dataCost + msgUp + msgDown + msgRight;
	
	% Για κάθε pixel της εικόνας
	for y = 2:height-1
		for x = 2:width-1
			% Στείλε μήνυμα πάνω
			msg = reshape(U(y,x,:),[dispLevels,1]);
			msg = min(msg+smoothnessCost);
			msg = msg-min(msg);
			msgDown(y-1,x,:) = msg;
			
			% Στείλε μήνυμα κάτω
			msg = reshape(D(y,x,:),[dispLevels,1]);
			msg = min(msg+smoothnessCost);
			msg = msg-min(msg);
			msgUp(y+1,x,:) = msg;
			
			% Στείλε μήνυμα δεξιά
			msg = reshape(R(y,x,:),[dispLevels,1]);
			msg = min(msg+smoothnessCost);
			msg = msg-min(msg);
			msgLeft(y,x+1,:) = msg;
			
			% Στείλε μήνυμα αριστερά
			msg = reshape(L(y,x,:),[dispLevels,1]);
			msg = min(msg+smoothnessCost);
			msg = msg-min(msg);
			msgRight(y,x-1,:) = msg;
		end
	end
	
	% Υπολόγισε το κόστος κάθε παράλλαξης (πεποίθηση)
	belief = dataCost + msgUp + msgDown + msgRight + msgLeft;
	
	% Δημιούργησε τον χάρτη παραλλάξεων
	[Y,I] = min(belief,[],3);
	dispMap = d(I);
	
	% Μετέτρεψε τον χάρτη παραλλάξεων σε εικόνα
	scaleFactor = 256/dispLevels;
	dispImage = uint8(dispMap*scaleFactor);
	
	% Εμφάνισε τον χάρτη παραλλάξεων
	imshow(dispImage)
	
	% Εμφάνισε τον αριθμό της τρέχουσας επανάληψης
	fprintf('iteration %d/%d\n',i,iterations)
end

% Αποθήκευσε τον τελικό χάρτη παραλλάξεων σε αρχείο
imwrite(dispImage,'Disparity.png')
