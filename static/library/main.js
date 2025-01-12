function handleReferral() {
    const referralCode = document.getElementById('referralCode').value;
    fetch('/.netlify/functions/referral', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ referralCode: referralCode }),
    })
    .then(response => response.json())
    .then(data => {
        console.log('Success:', data);
        alert('Referral processed!');
    })
    .catch((error) => {
        console.error('Error:', error);
        alert('Failed to process referral. Please try again.');
    });
}
